#!/bin/bash
# Script fix triệt để DATABASE_URL issue

set -e

cd /var/www/asset-rmg

echo "🔧 Final fix cho DATABASE_URL..."
echo "================================="

# 1. Tạo file .env đảm bảo đúng format
echo ""
echo "1️⃣  Tạo/kiểm tra file .env..."
cd backend

# Backup file cũ nếu có
if [ -f .env ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Đã backup file .env cũ"
fi

# Tạo file .env mới với format đúng
cat > .env << 'EOF'
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF

chmod 600 .env
echo "✅ Đã tạo file .env"

# Kiểm tra nội dung
echo ""
echo "📋 Nội dung file .env (ẩn password):"
cat .env | sed 's/:.*@/:****@/g'

# 2. Test load .env
echo ""
echo "2️⃣  Test load .env..."
if node -e "require('dotenv').config(); console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET')" 2>/dev/null; then
    echo "✅ Có thể load .env"
else
    echo "⚠️  Không thể load .env, kiểm tra lại"
fi

# 3. Pull code mới
echo ""
echo "3️⃣  Pull code mới..."
cd /var/www/asset-rmg
git pull origin main || echo "⚠️  Git pull failed"

# 4. Cài dotenv ở root
echo ""
echo "4️⃣  Đảm bảo dotenv có sẵn..."
if [ ! -f package.json ]; then
    echo '{"name":"asset-rmg-root","version":"1.0.0","dependencies":{"dotenv":"^16.0.0"}}' > package.json
fi

if [ ! -d node_modules/dotenv ]; then
    echo "📦 Cài dotenv..."
    npm install dotenv 2>/dev/null || {
        echo "⚠️  npm install failed, thử với --legacy-peer-deps"
        npm install dotenv --legacy-peer-deps 2>/dev/null || echo "❌ Vẫn không cài được dotenv"
    }
fi

# 5. Kiểm tra ecosystem.config.js
echo ""
echo "5️⃣  Kiểm tra ecosystem.config.js..."
if grep -q "DATABASE_URL.*process.env" ecosystem.config.js; then
    echo "✅ ecosystem.config.js có DATABASE_URL"
else
    echo "⚠️  ecosystem.config.js có thể chưa đúng"
fi

# 6. Dừng PM2 và start lại
echo ""
echo "6️⃣  Restart PM2..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 1

# Start với update env
echo "🚀 Starting PM2..."
pm2 start ecosystem.config.js --update-env

# Lưu config
pm2 save

# 7. Kiểm tra environment variables trong PM2
echo ""
echo "7️⃣  Kiểm tra env vars trong PM2..."
sleep 2
pm2 describe asset-rmg-api | grep -E "DATABASE_URL|JWT_SECRET" || echo "⚠️  Không thấy env vars"

# 8. Kiểm tra logs
echo ""
echo "8️⃣  Kiểm tra logs (đợi 5 giây)..."
sleep 5

echo ""
echo "📋 Logs (last 20 lines):"
pm2 logs asset-rmg-api --lines 20 --nostream || echo "⚠️  Chưa có logs"

# 9. Kiểm tra status
echo ""
echo "9️⃣  PM2 Status:"
pm2 status | grep asset-rmg-api || echo "⚠️  Process không hiển thị"

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn lỗi, thử:"
echo "   1. pm2 delete asset-rmg-api"
echo "   2. pm2 start ecosystem.config.js --update-env"
echo "   3. pm2 logs asset-rmg-api"
echo ""
echo "💡 Hoặc set env trực tiếp:"
echo "   pm2 set asset-rmg-api:DATABASE_URL 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db'"
echo "   pm2 restart asset-rmg-api"
