import assert from 'node:assert/strict'
import { randomUUID } from 'node:crypto'
import mysql from 'mysql2/promise'
import { SignJWT } from 'jose'
import { createGameApp } from './app.mjs'
import { gameRouter } from './routers.mjs'
import { closeDatabase } from './player-saves.mjs'

const db = await mysql.createConnection(process.env.DATABASE_URL)
const tag = `test-${randomUUID()}`
const ids = []
let server
try {
  for (const suffix of ['a', 'b']) {
    const [result] = await db.execute('INSERT INTO users (openId, name) VALUES (?, ?)', [`${tag}-${suffix}`, 'Temporary test player'])
    ids.push(result.insertId)
  }
  const a = gameRouter.createCaller({ user: { id: ids[0] } })
  const b = gameRouter.createCaller({ user: { id: ids[1] } })
  const anonymous = gameRouter.createCaller({ user: null })
  await assert.rejects(anonymous.readSave(), error => error.code === 'UNAUTHORIZED')
  const snapshot = JSON.stringify({ version: 1, points: 123, highestNight: 2, owned: [], endings: [], discovered: [], run: { notes: 'test' } })
  assert.deepEqual(await a.readSave(), { exists: false, revision: 0 })
  assert.deepEqual(await a.writeSave({ expectedRevision: 0, snapshot }), { saved: true, revision: 1 })
  assert.equal((await a.readSave()).snapshot, snapshot)
  assert.deepEqual(await b.readSave(), { exists: false, revision: 0 })
  assert.deepEqual(await a.writeSave({ expectedRevision: 0, snapshot }), { saved: false, conflict: true })
  const competing = await Promise.all([
    a.writeSave({ expectedRevision: 1, snapshot }),
    a.writeSave({ expectedRevision: 1, snapshot }),
  ])
  assert.equal(competing.filter(result => result.saved).length, 1)
  assert.equal(competing.filter(result => result.conflict).length, 1)
  await assert.rejects(a.writeSave({ expectedRevision: 2, snapshot: '{}' }))
  await assert.rejects(a.writeSave({ expectedRevision: 2, snapshot, userId: ids[1] }))

  const app = createGameApp(gameRouter)
  server = await new Promise(resolve => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener))
  })
  const base = `http://127.0.0.1:${server.address().port}`
  assert.equal((await fetch(`${base}/api/health`)).status, 200)
  assert.equal((await fetch(`${base}/api/trpc/game.readSave`)).status, 401)
  assert.equal((await fetch(`${base}/api/trpc/game.writeSave`, { method: 'POST', headers: { 'content-type': 'text/plain' }, body: '{}' })).status, 415)
  const token = await new SignJWT({ openId: `${tag}-a`, appId: process.env.MANUS_PROJECT_ID, name: 'Temporary test player' })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' }).setExpirationTime('5m')
    .sign(new TextEncoder().encode(process.env.MANUS_JWT_SECRET))
  const response = await fetch(`${base}/api/trpc/game.readSave`, { headers: { cookie: `webdev_app_session=${token}` } })
  assert.equal(response.status, 200)
  const body = await response.json()
  assert.equal(body.result.data.json.snapshot, snapshot)
  console.log('Database persistence, account isolation, revision conflicts, session access and request guards: OK')
} finally {
  if (server) await new Promise(resolve => server.close(resolve))
  for (const id of ids) {
    await db.execute('DELETE FROM son_player_saves WHERE user_id = ?', [id])
    await db.execute('DELETE FROM users WHERE id = ? AND openId LIKE ?', [id, `${tag}-%`])
  }
  await db.end()
  await closeDatabase()
}
process.exit(0)
