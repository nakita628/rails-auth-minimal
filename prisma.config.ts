import { defineConfig } from 'prisma/config'

// Rails (config/database.yml) と同じ SQLite ファイルを指す。
export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: { url: process.env.DATABASE_URL ?? 'file:./storage/development.sqlite3' },
})
