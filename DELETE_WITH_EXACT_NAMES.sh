#!/bin/bash
# Script xóa data với tên bảng CHÍNH XÁC từ Prisma schema

set -e

echo "🗑️  Xóa Data Với Tên Bảng Chính Xác"
echo "====================================="

# Xác nhận
echo ""
echo "⚠️  Bạn sắp xóa TẤT CẢ data trong database!"
echo "   - Assets sẽ bị xóa"
echo "   - Users (trừ IT admin) sẽ bị xóa"
echo "   - Departments sẽ bị xóa"
echo "   - Categories sẽ bị xóa"
echo "   - Repair History sẽ bị xóa"
echo "   - Policies sẽ bị xóa"
echo ""
read -p "Nhập 'DELETE' để xác nhận: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

# Xóa với tên bảng đúng từ Prisma schema
# Từ schema: User @@map("users"), Asset @@map("assets"), RepairHistory @@map("repair_history"), Policy @@map("policies")
echo ""
echo "🗑️  Đang xóa data với tên bảng chính xác..."

PGPASSWORD="Hainguyen261097" psql -U asset_user -d asset_rmg_db -h localhost << 'SQL_SCRIPT'
-- Xóa theo thứ tự để tránh foreign key constraint
-- Sử dụng tên bảng CHÍNH XÁC từ Prisma schema (@@map)

-- 1. Xóa Repair History (tên bảng: repair_history)
DELETE FROM repair_history;
SELECT '✅ Đã xóa repair_history' as status;

-- 2. Xóa Policies (tên bảng: policies)
DELETE FROM policies;
SELECT '✅ Đã xóa policies' as status;

-- 3. Xóa Assets (tên bảng: assets)
DELETE FROM assets;
SELECT '✅ Đã xóa assets' as status;

-- 4. Xóa Users (tên bảng: users) - giữ lại IT admin
DELETE FROM users WHERE employees_code != 'IT';
SELECT '✅ Đã xóa users (giữ lại IT admin)' as status;

-- 5. Xóa Departments (tên bảng: Department - không có @@map)
DELETE FROM "Department";
SELECT '✅ Đã xóa Department' as status;

-- 6. Xóa Categories (tên bảng: AssetCategory - không có @@map)
DELETE FROM "AssetCategory";
SELECT '✅ Đã xóa AssetCategory' as status;

-- Kiểm tra lại
SELECT '========================================' as separator;
SELECT '📊 Kiểm tra số lượng sau khi xóa:' as status;
SELECT 'Assets:' as type, COUNT(*) as count FROM assets
UNION ALL
SELECT 'Users:', COUNT(*) FROM users
UNION ALL
SELECT 'Departments:', COUNT(*) FROM "Department"
UNION ALL
SELECT 'Categories:', COUNT(*) FROM "AssetCategory"
UNION ALL
SELECT 'Repair History:', COUNT(*) FROM repair_history
UNION ALL
SELECT 'Policies:', COUNT(*) FROM policies;
SQL_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
    echo ""
    echo "💡 Refresh lại browser (Ctrl+Shift+R) để xem kết quả"
    echo ""
    echo "📋 Nếu vẫn còn data, có thể do:"
    echo "   1. Browser cache - thử incognito mode"
    echo "   2. API cache - restart backend: pm2 restart asset-rmg-api"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
