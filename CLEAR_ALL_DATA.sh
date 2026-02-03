#!/bin/bash

# Script để xóa toàn bộ dữ liệu, chỉ giữ lại IT user và dữ liệu cơ bản

set -e

echo "🗑️  Bắt đầu xóa toàn bộ dữ liệu (giữ lại IT user, categories, departments)..."

cd /var/www/asset-rmg/backend

# Set DATABASE_URL
export DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"

# Generate Prisma Client
echo "📦 Generating Prisma Client..."
npx prisma generate

# Run clear script
echo "🗑️  Running clear script..."
npx ts-node scripts/clear-all-keep-it.ts

echo ""
echo "✅ Hoàn tất! Đã xóa toàn bộ dữ liệu (trừ IT user, categories, departments)."
echo "📊 Bây giờ bạn có thể import lại dữ liệu từ Excel."
