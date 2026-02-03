#!/bin/bash
# Script liệt kê tất cả các bảng trong database

echo "📋 Liệt Kê Tất Cả Các Bảng Trong Database"
echo "=========================================="

PGPASSWORD="Hainguyen261097" psql -U asset_user -d asset_rmg_db -h localhost << 'SQL_SCRIPT'
-- Liệt kê tất cả các bảng
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY tablename;

-- Liệt kê số lượng records trong mỗi bảng
SELECT '========================================' as separator;
SELECT '📊 Số lượng records trong mỗi bảng:' as status;

-- Dynamic query để đếm records trong mỗi bảng
DO $$
DECLARE
    r RECORD;
    count_val INTEGER;
BEGIN
    FOR r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', r.tablename) INTO count_val;
        RAISE NOTICE 'Table: % | Count: %', r.tablename, count_val;
    END LOOP;
END $$;
SQL_SCRIPT
