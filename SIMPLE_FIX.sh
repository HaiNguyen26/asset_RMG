#!/bin/bash
# Simple fix - đảm bảo app chạy được

cd /var/www/asset-rmg

echo "🔧 Simple fix - đảm bảo app chạy được..."
echo "========================================="

# 1. Tạo file .env
echo ""
echo "1️⃣  Tạo file .env..."
cd backend
cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
chmod 600 .env
echo "✅ File .env đã tạo"

# 2. Pull code mới
echo ""
echo "2️⃣  Pull code mới..."
cd /var/www/asset-rmg
git pull origin main

# 3. Restart PM2
echo ""
echo "3️⃣  Restart PM2..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 1
pm2 start ecosystem.config.js
pm2 save

# 4. Kiểm tra
echo ""
echo "4️⃣  Kiểm tra (đợi 5 giây)..."
sleep 5

pm2 logs asset-rmg-api --lines 20 --nostream

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api
