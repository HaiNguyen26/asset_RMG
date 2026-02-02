import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'

// Try to use bcrypt, fallback to bcryptjs if bcrypt native bindings are not available
let bcrypt: any
try {
  bcrypt = require('bcrypt')
} catch (error) {
  try {
    bcrypt = require('bcryptjs')
    console.log('⚠️  Using bcryptjs (pure JS) instead of bcrypt (native)')
  } catch (e) {
    console.error('❌ Neither bcrypt nor bcryptjs is available. Please install one:')
    console.error('   npm install bcrypt')
    console.error('   OR')
    console.error('   npm install bcryptjs')
    process.exit(1)
  }
}

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is not set')
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL })
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

async function createAdmin() {
  try {
    // Get Tech department
    const deptTech = await prisma.department.findUnique({
      where: { code: 'TECH' },
    })

    if (!deptTech) {
      console.error('❌ Phòng Công nghệ (TECH) chưa tồn tại. Vui lòng chạy seed trước.')
      process.exit(1)
    }

    const hashedPassword = await bcrypt.hash('Hainguyen261097', 10)
    const admin = await prisma.user.upsert({
      where: { employeesCode: 'IT' },
      update: {
        password: hashedPassword,
        name: 'IT Admin',
        email: 'it.admin@company.com',
        branch: 'Hà Nội',
        role: 'ADMIN',
        departmentId: deptTech.id,
      },
      create: {
        employeesCode: 'IT',
        password: hashedPassword,
        name: 'IT Admin',
        email: 'it.admin@company.com',
        branch: 'Hà Nội',
        role: 'ADMIN',
        departmentId: deptTech.id,
      },
    })

    console.log('✅ Đã tạo/cập nhật tài khoản IT Admin thành công!')
    console.log(`   Mã nhân viên: ${admin.employeesCode}`)
    console.log(`   Tên: ${admin.name}`)
    console.log(`   Role: ${admin.role}`)
    console.log(`   Branch: ${admin.branch || 'Chưa có'}`)
    console.log('\n💡 Đăng nhập bằng:')
    console.log('   Mã nhân viên: IT')
    console.log('   Mật khẩu: Hainguyen261097')
  } catch (error: any) {
    console.error('❌ Lỗi khi tạo admin:', error.message)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
    await pool.end()
  }
}

createAdmin()
