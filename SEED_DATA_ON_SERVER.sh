#!/bin/bash

# Script để seed lại dữ liệu cơ bản (categories, departments, IT admin) trên server

set -e

echo "🌱 Bắt đầu seed dữ liệu cơ bản..."

cd /var/www/asset-rmg/backend

# Set DATABASE_URL
export DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"

echo "📦 Generating Prisma Client..."
npx prisma generate

echo "🌱 Running seed script..."
npm run prisma:seed

echo "✅ Seed hoàn tất!"
echo ""
echo "📋 Đã tạo:"
echo "   - Categories: Laptop, Phụ kiện IT, Thiết bị Kỹ thuật"
echo "   - Departments: Phòng Công nghệ, Phòng Hành chính, Phòng Kế toán, Kho"
echo "   - IT Admin user (employeesCode: IT, password: Hainguyen261097)"
echo ""
echo "🔄 Restarting backend..."
pm2 restart asset-rmg-api

echo "✅ Hoàn tất! Bây giờ có thể import Excel được rồi."
