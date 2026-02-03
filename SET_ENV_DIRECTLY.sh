#!/bin/bash
# Set environment variables trực tiếp trong PM2 (nếu cách khác không được)

cd /var/www/asset-rmg

echo "🔧 Set environment variables trực tiếp trong PM2..."
echo "==================================================="

# Dừng process
pm2 delete asset-rmg-api 2>/dev/null || true

# Set env variables trực tiếp
echo ""
echo "📝 Setting environment variables..."

pm2 start ecosystem.config.js --update-env

# Set trực tiếp qua PM2 (nếu cách trên không work)
pm2 set asset-rmg-api:DATABASE_URL "postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" 2>/dev/null || echo "⚠️  Không thể set qua pm2 set"

pm2 set asset-rmg-api:JWT_SECRET "your_jwt_secret_key_change_in_production_min_32_chars_please_change_this" 2>/dev/null || echo "⚠️  Không thể set qua pm2 set"

pm2 set asset-rmg-api:PORT "4001" 2>/dev/null || echo "⚠️  Không thể set qua pm2 set"

pm2 set asset-rmg-api:NODE_ENV "production" 2>/dev/null || echo "⚠️  Không thể set qua pm2 set"

# Restart để áp dụng
pm2 restart asset-rmg-api

# Lưu
pm2 save

echo ""
echo "✅ Đã set env variables"
echo ""
echo "📊 Kiểm tra:"
pm2 describe asset-rmg-api | grep -A 10 "env:"

echo ""
echo "📝 Logs:"
sleep 3
pm2 logs asset-rmg-api --lines 15 --nostream
