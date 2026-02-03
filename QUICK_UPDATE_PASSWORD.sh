#!/bin/bash
# Script nhanh để update password IT - không cần file script

set -e

echo "🔧 Update Password cho Tài khoản IT"
echo "===================================="

cd /var/www/asset-rmg/backend

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Chạy script inline với syntax đúng
echo ""
echo "🔄 Đang update password..."

DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" \
node << 'NODE_SCRIPT'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

async function updateITPassword() {
  try {
    console.log('🔧 Đang kết nối database...');
    const newPassword = 'Hainguyen261097';
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    console.log('🔍 Đang tìm tài khoản IT...');
    const user = await prisma.user.findUnique({
      where: { employeesCode: 'IT' },
    });
    
    if (!user) {
      console.log('📝 Tài khoản IT chưa có, đang tạo mới...');
      await prisma.user.create({
        data: {
          employeesCode: 'IT',
          name: 'IT Admin',
          password: hashedPassword,
          role: 'ADMIN',
        },
      });
      console.log('✅ Đã tạo tài khoản IT Admin mới');
    } else {
      console.log('📝 Tài khoản IT đã tồn tại, đang update password...');
      await prisma.user.update({
        where: { employeesCode: 'IT' },
        data: { password: hashedPassword },
      });
      console.log('✅ Đã cập nhật mật khẩu cho tài khoản IT');
    }
    
    console.log('');
    console.log('========================================');
    console.log('📋 Thông tin đăng nhập:');
    console.log('   Mã nhân viên: IT');
    console.log('   Mật khẩu: Hainguyen261097');
    console.log('   Role: ADMIN');
    console.log('========================================');
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    if (error.code) {
      console.error('   Error code:', error.code);
    }
    console.error('');
    console.error('Stack trace:');
    console.error(error.stack);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

updateITPassword();
NODE_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
    echo ""
    echo "🧪 Test đăng nhập:"
    echo "   curl -X POST http://localhost/asset_rmg/api/auth/login \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"employeesCode\":\"IT\",\"password\":\"Hainguyen261097\"}'"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
