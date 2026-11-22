import mysql from 'mysql2/promise'

let pool
function database() {
  if (!process.env.DATABASE_URL) throw new Error('database_unavailable')
  if (!pool) pool = mysql.createPool(process.env.DATABASE_URL)
  return pool
}

export async function databaseReady() {
  await database().query('SELECT 1 FROM son_schema_migrations LIMIT 1')
  const [rows] = await database().execute(
    'SELECT name FROM son_schema_migrations WHERE name IN (?, ?)',
    ['0000_initial_users.sql', '0001_player_saves.sql'],
  )
  return rows.length === 2
}

export async function readPlayerSave(userId) {
  const [rows] = await database().execute(
    'SELECT revision, snapshot FROM son_player_saves WHERE user_id = ?', [userId],
  )
  if (!rows.length) return { exists: false, revision: 0 }
  return { exists: true, revision: Number(rows[0].revision), snapshot: rows[0].snapshot }
}

export async function writePlayerSave(userId, expectedRevision, snapshot) {
  if (expectedRevision === 0) {
    try {
      await database().execute(
        'INSERT INTO son_player_saves (user_id, revision, snapshot) VALUES (?, 1, ?)',
        [userId, snapshot],
      )
      return { saved: true, revision: 1 }
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') return { saved: false, conflict: true }
      throw error
    }
  }
  const [result] = await database().execute(
    'UPDATE son_player_saves SET snapshot = ?, revision = revision + 1 WHERE user_id = ? AND revision = ?',
    [snapshot, userId, expectedRevision],
  )
  return result.affectedRows === 1
    ? { saved: true, revision: expectedRevision + 1 }
    : { saved: false, conflict: true }
}

export async function closeDatabase() {
  if (pool) await pool.end()
  pool = undefined
}
