#!/bin/bash

# Script đơn giản để setup database cho Asset RMG
# Chạy từng lệnh một để tránh lỗi

echo "🔧 Setting up database for Asset RMG..."

# Bước 1: Tạo database (nếu chưa có)
echo "📦 Step 1: Creating database..."
sudo -u postgres psql -c "CREATE DATABASE asset_rmg_db;" 2>/dev/null || echo "Database already exists, skipping..."

# Bước 2: Tạo user hoặc sửa password
echo "👤 Step 2: Creating/updating user..."
sudo -u postgres psql << 'SQL'
-- Tạo user hoặc sửa password
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'asset_user') THEN
        ALTER USER asset_user WITH PASSWORD 'Hainguyen261097';
        RAISE NOTICE 'User asset_user password updated';
    ELSE
        CREATE USER asset_user WITH PASSWORD 'Hainguyen261097';
        RAISE NOTICE 'User asset_user created';
    END IF;
END
$$;
SQL

# Bước 3: Grant privileges trên database
echo "🔐 Step 3: Granting database privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;"

# Bước 4: Grant privileges trên schema
echo "📋 Step 4: Granting schema privileges..."
sudo -u postgres psql -d asset_rmg_db << 'SQL'
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;
SQL

# Bước 5: Test connection
echo "✅ Step 5: Testing connection..."
sudo -u postgres psql -U asset_user -d asset_rmg_db -c "SELECT 1 as test;" && echo "✅ Connection successful!" || echo "❌ Connection failed!"

echo ""
echo "🎉 Database setup completed!"
echo ""
echo "Next steps:"
echo "1. Ensure .env file has: DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"
echo "2. Run: cd /var/www/asset-rmg/backend && npx prisma migrate deploy"
