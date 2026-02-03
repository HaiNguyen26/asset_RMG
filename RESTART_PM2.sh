#!/bin/bash
# Script đơn giản để restart PM2 với config mới

cd /var/www/asset-rmg

echo "🔄 Restarting PM2 với config mới..."
echo "===================================="

# Pull code mới
echo "📥 Pulling code..."
git pull origin main

# Dừng process cũ
echo "🛑 Stopping old process..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

# Start với config mới
echo "🚀 Starting PM2 với config mới..."
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
echo ""
echo "💡 Nếu thấy lỗi, kiểm tra:"
echo "   - pm2 describe asset-rmg-api | grep DATABASE_URL"
echo "   - pm2 logs asset-rmg-api"
