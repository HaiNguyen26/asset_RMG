#!/bin/bash
# Kiểm tra và fix PM2 env variables

cd /var/www/asset-rmg

echo "🔍 Kiểm tra PM2 environment variables..."
echo "========================================="

# 1. Kiểm tra env vars hiện tại trong PM2
echo ""
echo "1️⃣  Environment variables trong PM2:"
pm2 describe asset-rmg-api | grep -A 10 "env:" || echo "⚠️  Không thể lấy thông tin"

# 2. Kiểm tra DATABASE_URL cụ thể
echo ""
echo "2️⃣  Kiểm tra DATABASE_URL:"
DATABASE_URL=$(pm2 describe asset-rmg-api 2>/dev/null | grep "DATABASE_URL" | head -1)
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL KHÔNG có trong PM2 env!"
else
    echo "✅ DATABASE_URL có trong PM2:"
    echo "$DATABASE_URL" | sed 's/:.*@/:****@/g'
fi

# 3. Pull code mới
echo ""
echo "3️⃣  Pull code mới..."
git pull origin main

# 4. Kiểm tra ecosystem.config.js
echo ""
echo "4️⃣  Kiểm tra ecosystem.config.js:"
if grep -q "DATABASE_URL.*postgresql" ecosystem.config.js; then
    echo "✅ ecosystem.config.js có DATABASE_URL"
    grep "DATABASE_URL" ecosystem.config.js | sed 's/:.*@/:****@/g'
else
    echo "❌ ecosystem.config.js KHÔNG có DATABASE_URL!"
fi

# 5. Restart PM2 với --update-env
echo ""
echo "5️⃣  Restart PM2 với --update-env..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

echo "🚀 Starting PM2..."
pm2 start ecosystem.config.js --update-env

# Lưu config
pm2 save

# 6. Kiểm tra lại env vars sau restart
echo ""
echo "6️⃣  Kiểm tra env vars sau restart (đợi 3 giây)..."
sleep 3

echo ""
echo "📋 Environment variables trong PM2:"
pm2 describe asset-rmg-api | grep -A 10 "env:" || echo "⚠️  Không thể lấy thông tin"

# 7. Kiểm tra logs
echo ""
echo "7️⃣  Logs (last 25 lines):"
pm2 logs asset-rmg-api --lines 25 --nostream

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn lỗi DATABASE_URL:"
echo "   1. Kiểm tra: pm2 describe asset-rmg-api | grep DATABASE_URL"
echo "   2. Nếu không có, thử: pm2 restart asset-rmg-api --update-env"
echo "   3. Hoặc set trực tiếp: pm2 set asset-rmg-api:DATABASE_URL 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db'"
