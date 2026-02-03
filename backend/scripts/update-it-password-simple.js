// Script đơn giản để update password cho tài khoản IT
// Không phụ thuộc vào dotenv, set DATABASE_URL trực tiếp

const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcrypt')

// Set DATABASE_URL trực tiếp
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db'

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: DATABASE_URL
    }
  }
})

async function updateITPassword() {
  try {
    console.log('🔧 Đang kết nối database...')
    console.log('   DATABASE_URL:', DATABASE_URL.replace(/:[^:@]+@/, ':****@')) // Hide password
    
    const newPassword = 'Hainguyen261097'
    const hashedPassword = await bcrypt.hash(newPassword, 10)

    console.log('🔍 Đang tìm tài khoản IT...')
    // Tìm user IT
    const user = await prisma.user.findUnique({
      where: { employeesCode: 'IT' },
    })

    if (!user) {
      console.log('📝 Tài khoản IT chưa có, đang tạo mới...')
      // Nếu chưa có, tạo mới
      await prisma.user.create({
        data: {
          employeesCode: 'IT',
          name: 'IT Admin',
          password: hashedPassword,
          role: 'ADMIN',
        },
      })
      console.log('✅ Đã tạo tài khoản IT Admin mới')
    } else {
      console.log('📝 Tài khoản IT đã tồn tại, đang update password...')
      // Update password
      await prisma.user.update({
        where: { employeesCode: 'IT' },
        data: { password: hashedPassword },
      })
      console.log('✅ Đã cập nhật mật khẩu cho tài khoản IT')
    }

    console.log('')
    console.log('========================================')
    console.log('📋 Thông tin đăng nhập:')
    console.log('   Mã nhân viên: IT')
    console.log('   Mật khẩu: Hainguyen261097')
    console.log('   Role: ADMIN')
    console.log('========================================')
  } catch (error) {
    console.error('❌ Lỗi:', error.message)
    if (error.code) {
      console.error('   Error code:', error.code)
    }
    console.error('')
    console.error('Stack trace:')
    console.error(error.stack)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
  }
}

updateITPassword()
