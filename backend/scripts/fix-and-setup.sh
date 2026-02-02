#!/bin/bash

echo "🔧 Đang sửa lỗi và setup backend..."

# 1. Cài đặt dependencies
echo "📦 Bước 1: Cài đặt dependencies..."
npm install

# 2. Generate Prisma Client
echo "🔨 Bước 2: Generate Prisma Client..."
npx prisma generate

# 3. Chạy migration
echo "🗄️  Bước 3: Chạy migration..."
npx prisma migrate dev --name add_users_and_employees_code

# 4. Seed data (bao gồm IT admin)
echo "🌱 Bước 4: Seed dữ liệu..."
npx prisma db seed

echo "✅ Hoàn tất! Backend đã sẵn sàng."
echo ""
echo "💡 Tài khoản IT Admin:"
echo "   Mã nhân viên: IT"
echo "   Role: ADMIN"
