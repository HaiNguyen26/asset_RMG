#!/bin/bash
# Ultimate fix - Đảm bảo app đọc được DATABASE_URL

cd /var/www/asset-rmg

echo "🔧 Ultimate fix - Đảm bảo app đọc được DATABASE_URL..."
echo "======================================================="

# 1. Tạo file .env ở backend (app sẽ đọc từ đây)
echo ""
echo "1️⃣  Tạo file .env ở backend..."
cd backend

# Backup file cũ nếu có
if [ -f .env ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
fi

# Tạo file .env mới
cat > .env << 'EOF'
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF

chmod 600 .env
echo "✅ Đã tạo file .env ở backend/.env"

# Kiểm tra nội dung
echo ""
echo "📋 Nội dung file .env (ẩn password):"
cat .env | sed 's/:.*@/:****@/g'

# 2. Test load .env
echo ""
echo "2️⃣  Test load .env từ backend..."
cd /var/www/asset-rmg/backend
if node -e "require('dotenv').config(); console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'SET (' + process.env.DATABASE_URL.substring(0, 30) + '...)' : 'NOT SET')" 2>/dev/null; then
    echo "✅ Có thể load .env từ backend/"
else
    echo "⚠️  Không thể load .env, nhưng sẽ thử tiếp"
fi

# 3. Pull code mới
echo ""
echo "3️⃣  Pull code mới..."
cd /var/www/asset-rmg
git pull origin main

# 4. Dừng và restart PM2
echo ""
echo "4️⃣  Restart PM2..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

# Start với ecosystem.config.js (có env hardcoded)
pm2 start ecosystem.config.js

# Lưu config
pm2 save

# 5. Kiểm tra env trong PM2
echo ""
echo "5️⃣  Kiểm tra env trong PM2 (đợi 3 giây)..."
sleep 3

echo ""
echo "📋 Environment variables trong PM2:"
pm2 describe asset-rmg-api 2>/dev/null | grep -A 15 "env:" || echo "⚠️  Không thể lấy env vars"

# 6. Kiểm tra file .env có được app đọc không
echo ""
echo "6️⃣  Kiểm tra app có đọc được .env không..."
echo "   (App sẽ tự động load từ backend/.env khi chạy)"

# 7. Kiểm tra logs
echo ""
echo "7️⃣  Logs (last 30 lines, đợi 5 giây)..."
sleep 5

pm2 logs asset-rmg-api --lines 30 --nostream

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn lỗi DATABASE_URL:"
echo "   1. Kiểm tra file .env: cat /var/www/asset-rmg/backend/.env"
echo "   2. Kiểm tra app có đọc được: cd /var/www/asset-rmg/backend && node -e \"require('dotenv').config(); console.log(process.env.DATABASE_URL)\""
echo "   3. Kiểm tra PM2 working directory: pm2 describe asset-rmg-api | grep cwd"
echo "   4. Thử chạy app thủ công: cd /var/www/asset-rmg/backend && node dist/src/main.js"
