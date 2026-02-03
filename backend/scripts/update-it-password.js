// Script để update password cho tài khoản IT
require('dotenv').config({ path: require('path').join(__dirname, '../.env') })
const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcrypt')

const prisma = new PrismaClient()

async function updateITPassword() {
  try {
    const newPassword = 'Hainguyen261097'
    const hashedPassword = await bcrypt.hash(newPassword, 10)

    // Tìm user IT
    const user = await prisma.user.findUnique({
      where: { employeesCode: 'IT' },
    })

    if (!user) {
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
      // Update password
      await prisma.user.update({
        where: { employeesCode: 'IT' },
        data: { password: hashedPassword },
      })
      console.log('✅ Đã cập nhật mật khẩu cho tài khoản IT')
    }

    console.log('')
    console.log('📋 Thông tin đăng nhập:')
    console.log('   Mã nhân viên: IT')
    console.log('   Mật khẩu: Hainguyen261097')
    console.log('   Role: ADMIN')
  } catch (error) {
    console.error('❌ Lỗi:', error.message)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
  }
}

updateITPassword()
