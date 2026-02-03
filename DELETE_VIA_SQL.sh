#!/bin/bash
# Script xóa data trực tiếp bằng SQL - đảm bảo xóa được

set -e

echo "🗑️  Xóa Data Trực Tiếp Bằng SQL"
echo "=================================="

# Xác nhận
echo ""
echo "⚠️  ⚠️  ⚠️  CẢNH BÁO ⚠️  ⚠️  ⚠️"
echo "   Bạn sắp xóa TẤT CẢ data trong database!"
echo "   Điều này không thể hoàn tác!"
echo ""
read -p "Nhập 'DELETE' để xác nhận: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

# Xóa bằng SQL trực tiếp
echo ""
echo "🗑️  Đang xóa data bằng SQL..."

PGPASSWORD="Hainguyen261097" psql -U asset_user -d asset_rmg_db -h localhost << 'SQL_SCRIPT'
-- Xóa theo thứ tự để tránh foreign key constraint

-- 1. Xóa Repair History
DELETE FROM "RepairHistory";
SELECT '✅ Đã xóa Repair History' as status;

-- 2. Xóa Policies
DELETE FROM "Policy";
SELECT '✅ Đã xóa Policies' as status;

-- 3. Xóa Assets
DELETE FROM "Asset";
SELECT '✅ Đã xóa Assets' as status;

-- 4. Xóa Users (giữ lại IT admin)
DELETE FROM "User" WHERE "employeesCode" != 'IT';
SELECT '✅ Đã xóa Users (giữ lại IT admin)' as status;

-- 5. Xóa Departments
DELETE FROM "Department";
SELECT '✅ Đã xóa Departments' as status;

-- 6. Xóa Categories
DELETE FROM "Category";
SELECT '✅ Đã xóa Categories' as status;

-- Kiểm tra lại
SELECT '========================================' as separator;
SELECT '📊 Kiểm tra số lượng sau khi xóa:' as status;
SELECT COUNT(*) as "Assets" FROM "Asset";
SELECT COUNT(*) as "Users" FROM "User";
SELECT COUNT(*) as "Departments" FROM "Department";
SELECT COUNT(*) as "Categories" FROM "Category";
SELECT COUNT(*) as "RepairHistory" FROM "RepairHistory";
SELECT COUNT(*) as "Policies" FROM "Policy";
SQL_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
    echo ""
    echo "💡 Refresh lại browser (Ctrl+Shift+R) để xem kết quả"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    echo "   Kiểm tra database connection và permissions"
    exit 1
fi
