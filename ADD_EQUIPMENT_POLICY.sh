#!/bin/bash

# Script để thêm/chỉnh sửa chính sách Cấp phát thiết bị trên server

set -e

echo "📝 Đang thêm/chỉnh sửa chính sách Cấp phát thiết bị..."

cd /var/www/asset-rmg/backend

# Set DATABASE_URL
export DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"

# Generate Prisma Client
echo "📦 Generating Prisma Client..."
npx prisma generate

# Run script to add policy
echo "📝 Running policy script..."
npm run add-equipment-policy

echo ""
echo "✅ Hoàn tất! Chính sách Cấp phát thiết bị đã được thêm/chỉnh sửa."
echo "🌐 Truy cập: http://27.71.16.15/asset_rmg/policies để xem."
