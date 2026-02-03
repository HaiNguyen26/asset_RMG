#!/bin/bash
# Start PM2 với env variables được export trước

cd /var/www/asset-rmg

echo "🚀 Start PM2 với env variables được export..."
echo "=============================================="

# Export env variables
export DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"
export JWT_SECRET="your_jwt_secret_key_change_in_production_min_32_chars_please_change_this"
export PORT=4001
export NODE_ENV=production

echo "✅ Đã export env variables:"
echo "   DATABASE_URL: postgresql://asset_user:****@localhost:5432/asset_rmg_db"
echo "   PORT: 4001"
echo "   NODE_ENV: production"

# Pull code mới
echo ""
echo "📥 Pull code mới..."
git pull origin main

# Dừng process cũ
echo ""
echo "🛑 Dừng process cũ..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

# Start với env đã export
echo ""
echo "🚀 Starting PM2 với env variables..."
pm2 start ecosystem.config.js

# Lưu config
pm2 save

# Kiểm tra
echo ""
echo "⏳ Đợi 5 giây để app khởi động..."
sleep 5

echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api

echo ""
echo "📝 Logs (last 20 lines):"
pm2 logs asset-rmg-api --lines 20 --nostream

echo ""
echo "✅ Hoàn thành!"
