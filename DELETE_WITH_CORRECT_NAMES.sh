#!/bin/bash
# Script xóa data với tên bảng đúng (tự động detect)

set -e

echo "🗑️  Xóa Data Với Tên Bảng Đúng"
echo "==============================="

# Xác nhận
echo ""
echo "⚠️  Bạn sắp xóa TẤT CẢ data trong database!"
read -p "Nhập 'DELETE' để xác nhận: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

# Xóa với tên bảng đúng (lowercase hoặc snake_case)
echo ""
echo "🗑️  Đang xóa data..."

PGPASSWORD="Hainguyen261097" psql -U asset_user -d asset_rmg_db -h localhost << 'SQL_SCRIPT'
-- Xóa theo thứ tự để tránh foreign key constraint
-- Thử cả PascalCase và lowercase

-- 1. Xóa Repair History (thử cả 2 tên)
DO $$
BEGIN
    BEGIN
        DELETE FROM "RepairHistory";
        RAISE NOTICE '✅ Đã xóa RepairHistory';
    EXCEPTION WHEN undefined_table THEN
        BEGIN
            DELETE FROM repair_history;
            RAISE NOTICE '✅ Đã xóa repair_history';
        EXCEPTION WHEN undefined_table THEN
            RAISE NOTICE '⚠️  Không tìm thấy bảng RepairHistory';
        END;
    END;
END $$;

-- 2. Xóa Policies
DO $$
BEGIN
    BEGIN
        DELETE FROM "Policy";
        RAISE NOTICE '✅ Đã xóa Policy';
    EXCEPTION WHEN undefined_table THEN
        BEGIN
            DELETE FROM policy;
            RAISE NOTICE '✅ Đã xóa policy';
        EXCEPTION WHEN undefined_table THEN
            RAISE NOTICE '⚠️  Không tìm thấy bảng Policy';
        END;
    END;
END $$;

-- 3. Xóa Assets
DO $$
BEGIN
    BEGIN
        DELETE FROM "Asset";
        RAISE NOTICE '✅ Đã xóa Asset';
    EXCEPTION WHEN undefined_table THEN
        BEGIN
            DELETE FROM asset;
            RAISE NOTICE '✅ Đã xóa asset';
        EXCEPTION WHEN undefined_table THEN
            RAISE NOTICE '⚠️  Không tìm thấy bảng Asset';
        END;
    END;
END $$;

-- 4. Xóa Users (giữ lại IT admin)
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    BEGIN
        DELETE FROM "User" WHERE "employeesCode" != 'IT';
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ Đã xóa % users từ User', deleted_count;
    EXCEPTION WHEN undefined_table THEN
        BEGIN
            DELETE FROM "user" WHERE employees_code != 'IT';
            GET DIAGNOSTICS deleted_count = ROW_COUNT;
            RAISE NOTICE '✅ Đã xóa % users từ user', deleted_count;
        EXCEPTION WHEN undefined_table THEN
            RAISE NOTICE '⚠️  Không tìm thấy bảng User';
        END;
    END;
END $$;

-- 5. Xóa Departments
DO $$
BEGIN
    BEGIN
        DELETE FROM "Department";
        RAISE NOTICE '✅ Đã xóa Department';
    EXCEPTION WHEN undefined_table THEN
        BEGIN
            DELETE FROM department;
            RAISE NOTICE '✅ Đã xóa department';
        EXCEPTION WHEN undefined_table THEN
            RAISE NOTICE '⚠️  Không tìm thấy bảng Department';
        END;
    END;
END $$;

-- 6. Xóa Categories
DO $$
BEGIN
    BEGIN
        DELETE FROM "Category";
        RAISE NOTICE '✅ Đã xóa Category';
    EXCEPTION WHEN undefined_table THEN
        BEGIN
            DELETE FROM category;
            RAISE NOTICE '✅ Đã xóa category';
        EXCEPTION WHEN undefined_table THEN
            RAISE NOTICE '⚠️  Không tìm thấy bảng Category';
        END;
    END;
END $$;

-- Kiểm tra lại
SELECT '========================================' as separator;
SELECT '📊 Kiểm tra số lượng sau khi xóa:' as status;

-- Kiểm tra từng bảng
DO $$
DECLARE
    r RECORD;
    count_val INTEGER;
    table_name TEXT;
BEGIN
    FOR r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
        AND tablename IN ('Asset', 'asset', 'User', 'user', 'Department', 'department', 'Category', 'category', 'RepairHistory', 'repair_history', 'Policy', 'policy')
        ORDER BY tablename
    LOOP
        table_name := r.tablename;
        BEGIN
            EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO count_val;
            RAISE NOTICE 'Table: % | Count: %', table_name, count_val;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Table: % | Error: %', table_name, SQLERRM;
        END;
    END LOOP;
END $$;
SQL_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
    echo ""
    echo "💡 Refresh lại browser để xem kết quả"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
