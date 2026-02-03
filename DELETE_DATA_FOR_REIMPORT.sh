#!/bin/bash

# Script để xóa dữ liệu để import lại
# Giữ lại: Categories, Departments, IT Admin user

set -e

echo "🗑️  Bắt đầu xóa dữ liệu để import lại..."
echo "⚠️  Sẽ xóa: Assets, Users (trừ IT Admin), Repair History, Policies"
echo "✅ Giữ lại: Categories, Departments, IT Admin user"
echo ""
read -p "Bạn có chắc chắn muốn tiếp tục? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Đã hủy."
    exit 1
fi

cd /var/www/asset-rmg/backend

# Set DATABASE_URL
export DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"

echo "📦 Generating Prisma Client..."
npx prisma generate

echo "🗑️  Xóa dữ liệu..."

# Xóa theo thứ tự để tránh foreign key constraint errors
# 1. Xóa Repair History (có foreign key đến assets và users)
psql "$DATABASE_URL" -c "DELETE FROM repair_history;" || echo "⚠️  Không có repair_history để xóa"

# 2. Xóa Policies
psql "$DATABASE_URL" -c "DELETE FROM policies;" || echo "⚠️  Không có policies để xóa"

# 3. Xóa Assets (có foreign key đến users và departments)
psql "$DATABASE_URL" -c "DELETE FROM assets;" || echo "⚠️  Không có assets để xóa"

# 4. Xóa Users (trừ IT Admin)
psql "$DATABASE_URL" -c "DELETE FROM users WHERE employees_code != 'IT';" || echo "⚠️  Không có users để xóa"

echo ""
echo "✅ Đã xóa dữ liệu thành công!"
echo ""
echo "📊 Kiểm tra dữ liệu còn lại:"
psql "$DATABASE_URL" -c "
SELECT 
  (SELECT COUNT(*) FROM \"AssetCategory\") as categories,
  (SELECT COUNT(*) FROM \"Department\") as departments,
  (SELECT COUNT(*) FROM users WHERE employees_code = 'IT') as it_admin,
  (SELECT COUNT(*) FROM assets) as assets,
  (SELECT COUNT(*) FROM users WHERE employees_code != 'IT') as other_users,
  (SELECT COUNT(*) FROM repair_history) as repair_history,
  (SELECT COUNT(*) FROM policies) as policies;
"

echo ""
echo "✅ Hoàn tất! Bây giờ có thể import Excel lại."
echo "📝 Lưu ý:"
echo "   - Categories và Departments vẫn còn"
echo "   - IT Admin user vẫn còn (employeesCode: IT, password: Hainguyen261097)"
echo "   - Có thể import Excel để tạo lại assets và users"
