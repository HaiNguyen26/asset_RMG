#!/bin/bash
# Script kiểm tra số lượng data bằng SQL

echo "🔍 Kiểm Tra Số Lượng Data (SQL)"
echo "================================="

PGPASSWORD="Hainguyen261097" psql -U asset_user -d asset_rmg_db -h localhost << 'SQL_SCRIPT'
SELECT '📊 Số lượng data hiện tại:' as status;
SELECT '========================================' as separator;
SELECT 'Assets:' as type, COUNT(*) as count FROM "Asset"
UNION ALL
SELECT 'Users:', COUNT(*) FROM "User"
UNION ALL
SELECT 'Departments:', COUNT(*) FROM "Department"
UNION ALL
SELECT 'Categories:', COUNT(*) FROM "Category"
UNION ALL
SELECT 'Repair History:', COUNT(*) FROM "RepairHistory"
UNION ALL
SELECT 'Policies:', COUNT(*) FROM "Policy";

SELECT '' as separator;

SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM "Asset") > 0 THEN '⚠️  Vẫn còn Assets!'
    ELSE '✅ Assets đã được xóa'
  END as assets_status,
  CASE 
    WHEN (SELECT COUNT(*) FROM "Department") > 0 THEN '⚠️  Vẫn còn Departments!'
    ELSE '✅ Departments đã được xóa'
  END as depts_status,
  CASE 
    WHEN (SELECT COUNT(*) FROM "Category") > 0 THEN '⚠️  Vẫn còn Categories!'
    ELSE '✅ Categories đã được xóa'
  END as cats_status;
SQL_SCRIPT
