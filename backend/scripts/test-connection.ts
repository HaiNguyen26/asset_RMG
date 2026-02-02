import 'dotenv/config'
import { Pool } from 'pg'

const databaseUrl = process.env.DATABASE_URL

if (!databaseUrl) {
  console.error('❌ DATABASE_URL không được set trong .env')
  process.exit(1)
}

console.log('🔍 Đang kiểm tra kết nối database...')
console.log(`   Connection string: ${databaseUrl.replace(/:[^:@]+@/, ':****@')}`) // Hide password

const pool = new Pool({ connectionString: databaseUrl })

pool
  .connect()
  .then((client) => {
    console.log('✅ Kết nối database thành công!')
    return client.query('SELECT NOW()')
  })
  .then((result) => {
    console.log(`   Database time: ${result.rows[0].now}`)
    pool.end()
    process.exit(0)
  })
  .catch((error) => {
    console.error('❌ Lỗi kết nối database:', error.message)
    if (error.message.includes('password must be a string')) {
      console.error('\n💡 Vấn đề: Password không đúng định dạng')
      console.error('   Kiểm tra DATABASE_URL trong file .env')
      console.error('   Đảm bảo password được đặt trong dấu ngoặc kép')
    }
    pool.end()
    process.exit(1)
  })
