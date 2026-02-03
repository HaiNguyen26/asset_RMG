#!/bin/bash
# Quick fix cho DATABASE_URL issue

cd /var/www/asset-rmg

echo "🔧 Quick fix DATABASE_URL..."
echo "============================"

# 1. Đảm bảo file .env tồn tại
echo ""
echo "1️⃣  Tạo/kiểm tra file .env..."
cd backend
if [ ! -f .env ]; then
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
chmod 600 .env

# 2. Pull code mới
echo ""
echo "2️⃣  Pull code mới..."
cd /var/www/asset-rmg
git pull origin main

# 3. Cài dotenv ở root nếu chưa có
echo ""
echo "3️⃣  Kiểm tra dotenv..."
if [ ! -d node_modules/dotenv ]; then
    if [ ! -f package.json ]; then
        echo '{"name":"asset-rmg-root","version":"1.0.0","dependencies":{"dotenv":"^16.0.0"}}' > package.json
    fi
    npm install dotenv 2>/dev/null || echo "⚠️  Cần cài dotenv: npm install dotenv"
fi

# 4. Restart PM2 với --update-env
echo ""
echo "4️⃣  Restart PM2..."
pm2 delete asset-rmg-api 2>/dev/null || true
pm2 start ecosystem.config.js --update-env
pm2 save

# 5. Kiểm tra
echo ""
echo "5️⃣  Kiểm tra (đợi 3 giây)..."
sleep 3
pm2 logs asset-rmg-api --lines 15 --nostream

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api

echo ""
echo "📝 Nếu vẫn lỗi, thử:"
echo "   pm2 restart asset-rmg-api --update-env"
