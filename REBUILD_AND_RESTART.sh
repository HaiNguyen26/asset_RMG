#!/bin/bash
# Rebuild backend và restart PM2 sau khi thay đổi code

cd /var/www/asset-rmg

echo "🔄 Rebuild và Restart sau khi thay đổi code..."
echo "=============================================="

# 1. Pull code mới nhất
echo ""
echo "1️⃣  Pull code mới nhất..."
git pull origin main

# 2. Rebuild Backend
echo ""
echo "2️⃣  Rebuilding backend..."
cd backend

# Xóa dist cũ
rm -rf dist

# Build lại
npm run build

# Kiểm tra build thành công
if [ ! -f dist/src/main.js ]; then
    echo "❌ Build failed! File dist/src/main.js không tồn tại"
    exit 1
fi

echo "✅ Backend build thành công"

# 3. Restart PM2
echo ""
echo "3️⃣  Restarting PM2..."
cd /var/www/asset-rmg

# Dừng process cũ
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

# Start với code mới
pm2 start ecosystem.config.js
pm2 save

# 4. Kiểm tra
echo ""
echo "4️⃣  Kiểm tra (đợi 5 giây)..."
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
echo "💡 Lưu ý:"
echo "   - Sau khi thay đổi code, LUÔN cần rebuild và restart PM2"
echo "   - Code trong src/ chỉ là source code"
echo "   - PM2 chạy code từ dist/ (đã build)"
echo "   - Nếu không rebuild, PM2 vẫn chạy code cũ"
