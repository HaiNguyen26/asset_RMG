const { Client } = require('pg')
require('dotenv').config({ path: '.env' })

const DATABASE_NAME = 'asset_management'

// Lấy connection string từ .env và thay đổi database name thành 'postgres' (database mặc định)
const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:Hainguyen261097@localhost:5432/postgres?schema=public'
const connectionString = dbUrl.replace(/\/[^/]+(\?|$)/, '/postgres$1')

async function createDatabase() {
  const client = new Client({ connectionString })

  try {
    console.log('🔌 Đang kết nối đến PostgreSQL server...')
    await client.connect()
    console.log('✅ Đã kết nối thành công!')

    // Kiểm tra xem database đã tồn tại chưa
    const checkResult = await client.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [DATABASE_NAME]
    )

    if (checkResult.rows.length > 0) {
      console.log(`⚠️  Database "${DATABASE_NAME}" đã tồn tại.`)
      return
    }

    // Tạo database mới
    console.log(`📦 Đang tạo database "${DATABASE_NAME}"...`)
    await client.query(`CREATE DATABASE ${DATABASE_NAME}`)
    console.log(`✅ Đã tạo database "${DATABASE_NAME}" thành công!`)
    console.log('\n🎉 Hoàn tất! Bạn có thể chạy migration và seed:')
    console.log('   npx prisma migrate dev --name init')
    console.log('   npx prisma db seed')
  } catch (error) {
    console.error('❌ Lỗi khi tạo database:', error.message)
    if (error.message.includes('password authentication failed')) {
      console.error('\n💡 Kiểm tra lại username và password trong file .env')
    } else if (error.message.includes('ECONNREFUSED')) {
      console.error('\n💡 Đảm bảo PostgreSQL server đang chạy')
    }
    process.exit(1)
  } finally {
    await client.end()
  }
}

createDatabase()
