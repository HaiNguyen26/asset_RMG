#!/bin/bash
# Script update password cho tài khoản IT

set -e

echo "🔧 Update Password cho Tài khoản IT"
echo "===================================="

PROJECT_PATH="/var/www/asset-rmg"
BACKEND_PATH="$PROJECT_PATH/backend"

cd "$BACKEND_PATH"

# Kiểm tra .env
if [ ! -f .env ]; then
    echo "⚠️  File .env không tồn tại, tạo mới..."
    cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
fi

# Kiểm tra script có tồn tại không
if [ ! -f "scripts/update-it-password.js" ]; then
    echo "⚠️  Script không tồn tại, tạo mới..."
    mkdir -p scripts
    
    cat > scripts/update-it-password.js << 'SCRIPT_EOF'
// Script để update password cho tài khoản IT
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
SCRIPT_EOF
fi

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Chạy script (thử script đơn giản trước)
echo ""
echo "🔄 Đang update password..."

if [ -f "scripts/update-it-password-simple.js" ]; then
    echo "   Sử dụng script đơn giản..."
    DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" \
    node scripts/update-it-password-simple.js
else
    echo "   Sử dụng script thông thường..."
    DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" \
    node scripts/update-it-password.js
fi

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
