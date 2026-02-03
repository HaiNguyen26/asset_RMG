#!/bin/bash
# Force fix - Set env trực tiếp trong PM2

cd /var/www/asset-rmg

echo "🔧 Force fix - Set env trực tiếp trong PM2..."
echo "=============================================="

# 1. Pull code mới
echo ""
echo "1️⃣  Pull code mới..."
git pull origin main

# 2. Dừng process
echo ""
echo "2️⃣  Dừng process cũ..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

# 3. Start với ecosystem.config.js
echo ""
echo "3️⃣  Start PM2 với ecosystem.config.js..."
pm2 start ecosystem.config.js

# 4. Set env trực tiếp qua PM2 (force)
echo ""
echo "4️⃣  Set environment variables trực tiếp trong PM2..."
pm2 set asset-rmg-api:DATABASE_URL "postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" 2>/dev/null || echo "⚠️  pm2 set không work, sẽ dùng cách khác"

pm2 set asset-rmg-api:JWT_SECRET "your_jwt_secret_key_change_in_production_min_32_chars_please_change_this" 2>/dev/null || echo "⚠️  pm2 set không work"

pm2 set asset-rmg-api:PORT "4001" 2>/dev/null || echo "⚠️  pm2 set không work"

pm2 set asset-rmg-api:NODE_ENV "production" 2>/dev/null || echo "⚠️  pm2 set không work"

# 5. Restart để áp dụng
echo ""
echo "5️⃣  Restart để áp dụng env mới..."
pm2 restart asset-rmg-api --update-env

# Lưu config
pm2 save

# 6. Kiểm tra env vars
echo ""
echo "6️⃣  Kiểm tra env vars trong PM2 (đợi 3 giây)..."
sleep 3

echo ""
echo "📋 Environment variables:"
pm2 describe asset-rmg-api 2>/dev/null | grep -A 15 "env:" || {
    echo "⚠️  Không thể lấy env vars, thử cách khác..."
    echo ""
    echo "💡 Thử export env trước khi start:"
    echo "   export DATABASE_URL='postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db'"
    echo "   pm2 restart asset-rmg-api"
}

# 7. Kiểm tra logs
echo ""
echo "7️⃣  Logs (last 25 lines):"
pm2 logs asset-rmg-api --lines 25 --nostream

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn lỗi, thử cách cuối cùng:"
echo "   cd /var/www/asset-rmg/backend"
echo "   export DATABASE_URL='postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db'"
echo "   export JWT_SECRET='your_jwt_secret_key_change_in_production_min_32_chars_please_change_this'"
echo "   export PORT=4001"
echo "   export NODE_ENV=production"
echo "   cd /var/www/asset-rmg"
echo "   pm2 delete asset-rmg-api"
echo "   pm2 start ecosystem.config.js"
