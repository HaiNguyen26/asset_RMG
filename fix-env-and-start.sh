#!/bin/bash
# Script tự động fix environment variables và start PM2

set -e

cd /var/www/asset-rmg

echo "🔧 Fixing environment variables and starting PM2..."
echo "=================================================="

# 1. Kiểm tra và tạo file .env
echo ""
echo "1️⃣  Kiểm tra file .env..."
cd backend

if [ ! -f .env ]; then
    echo "⚠️  File .env không tồn tại, tạo file mới..."
    cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
    echo "✅ Đã tạo file .env"
else
    echo "✅ File .env đã tồn tại"
fi

# Kiểm tra nội dung DATABASE_URL
if grep -q "DATABASE_URL" .env; then
    echo "✅ DATABASE_URL có trong file .env"
    # Hiển thị (ẩn password)
    grep "DATABASE_URL" .env | sed 's/:.*@/:****@/g'
else
    echo "❌ DATABASE_URL KHÔNG có trong file .env!"
    echo "➕ Thêm DATABASE_URL vào file .env..."
    echo "DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" >> .env
fi

# Set permissions
chmod 600 .env
echo "✅ Set permissions cho .env"

# 2. Cài dotenv ở root (nếu cần)
echo ""
echo "2️⃣  Kiểm tra dotenv..."
cd /var/www/asset-rmg

if [ ! -f package.json ]; then
    echo "⚠️  Không có package.json ở root, tạo file..."
    cat > package.json << EOF
{
  "name": "asset-rmg-root",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "dotenv": "^16.0.0"
  }
}
EOF
fi

if [ ! -d node_modules/dotenv ]; then
    echo "⚠️  dotenv chưa cài, đang cài..."
    npm install dotenv 2>/dev/null || echo "⚠️  npm install failed, có thể cần cài thủ công"
else
    echo "✅ dotenv đã cài"
fi

# 3. Pull code mới nhất
echo ""
echo "3️⃣  Pull code mới nhất..."
git pull origin main || echo "⚠️  Git pull failed hoặc không có thay đổi"

# 4. Kiểm tra ecosystem.config.js
echo ""
echo "4️⃣  Kiểm tra ecosystem.config.js..."
if grep -q "require('dotenv')" ecosystem.config.js; then
    echo "✅ ecosystem.config.js đã có dotenv"
else
    echo "⚠️  ecosystem.config.js chưa có dotenv, cần pull code mới"
fi

# 5. Test load .env
echo ""
echo "5️⃣  Test load .env..."
cd backend
if node -e "require('dotenv').config(); console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'SET (' + process.env.DATABASE_URL.substring(0, 30) + '...)' : 'NOT SET')" 2>/dev/null; then
    echo "✅ Có thể load .env từ backend/"
else
    echo "⚠️  Không thể load .env, kiểm tra lại file"
fi

# 6. Restart PM2
echo ""
echo "6️⃣  Restart PM2..."
cd /var/www/asset-rmg

# Dừng process cũ
pm2 delete asset-rmg-api 2>/dev/null || true

# Start lại
echo "🚀 Starting PM2..."
pm2 start ecosystem.config.js

# Lưu config
pm2 save

# 7. Kiểm tra logs
echo ""
echo "7️⃣  Kiểm tra logs (đợi 3 giây)..."
sleep 3

pm2 logs asset-rmg-api --lines 20 --nostream || echo "⚠️  Chưa có logs"

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api || echo "⚠️  Process không hiển thị"

echo ""
echo "📝 Xem logs real-time:"
echo "   pm2 logs asset-rmg-api"
