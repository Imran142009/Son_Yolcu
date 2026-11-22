import { readFile } from 'node:fs/promises'
import mysql from 'mysql2/promise'

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required')
const connection = await mysql.createConnection(process.env.DATABASE_URL)
try {
  await connection.query(`CREATE TABLE IF NOT EXISTS son_schema_migrations (
    name varchar(190) NOT NULL PRIMARY KEY,
    applied_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`)
  for (const name of ['0000_initial_users.sql', '0001_player_saves.sql']) {
    const [rows] = await connection.execute('SELECT name FROM son_schema_migrations WHERE name = ?', [name])
    if (rows.length) continue
    const sql = await readFile(new URL(name, import.meta.url), 'utf8')
    await connection.query(sql)
    await connection.execute('INSERT INTO son_schema_migrations (name) VALUES (?)', [name])
    console.log(`Applied ${name}`)
  }
} finally {
  await connection.end()
}
