import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is not set')
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL })
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

async function checkUser() {
  try {
    console.log('🔍 Đang kiểm tra user IT...\n')

    const user = await prisma.user.findUnique({
      where: { employeesCode: 'IT' },
      include: { department: true },
    })

    if (user) {
      console.log('✅ User IT đã tồn tại:')
      console.log(`   ID: ${user.id}`)
      console.log(`   Mã nhân viên: ${user.employeesCode}`)
      console.log(`   Tên: ${user.name}`)
      console.log(`   Email: ${user.email || '—'}`)
      console.log(`   Role: ${user.role}`)
      console.log(`   Phòng ban: ${user.department?.name || '—'}`)
    } else {
      console.log('❌ User IT chưa tồn tại!')
      console.log('\n💡 Chạy lệnh sau để tạo:')
      console.log('   npm run create-admin')
    }

    // List all users
    const allUsers = await prisma.user.findMany({
      include: { department: true },
    })
    console.log(`\n📊 Tổng số users trong database: ${allUsers.length}`)
    if (allUsers.length > 0) {
      console.log('\nDanh sách users:')
      allUsers.forEach((u) => {
        console.log(`   - ${u.employeesCode}: ${u.name} (${u.role})`)
      })
    }
  } catch (error: any) {
    console.error('❌ Lỗi:', error.message)
    if (error.message.includes("does not exist")) {
      console.error('\n💡 Có vẻ như User table chưa tồn tại.')
      console.error('   Chạy migration: npx prisma migrate dev')
    }
  } finally {
    await prisma.$disconnect()
    await pool.end()
  }
}

checkUser()
