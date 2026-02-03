#!/bin/bash
# Fix cuối cùng - Tạo .env ở cả root và backend

cd /var/www/asset-rmg

echo "🔧 Fix cuối cùng - Tạo .env ở cả root và backend..."
echo "===================================================="

# 1. Tạo file .env ở backend (app sẽ đọc từ đây khi chạy)
echo ""
echo "1️⃣  Tạo file .env ở backend/..."
cd backend
cat > .env << 'EOF'
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
chmod 600 .env
echo "✅ Đã tạo backend/.env"

# 2. Tạo file .env ở root (PM2 có thể đọc từ đây)
echo ""
echo "2️⃣  Tạo file .env ở root..."
cd /var/www/asset-rmg
cat > .env << 'EOF'
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
chmod 600 .env
echo "✅ Đã tạo root/.env"

# 3. Pull code mới
echo ""
echo "3️⃣  Pull code mới..."
git pull origin main

# 4. Dừng và restart PM2
echo ""
echo "4️⃣  Restart PM2..."
pm2 delete asset-rmg-api 2>/dev/null || true
sleep 2

# Export env trước khi start
export DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"
export JWT_SECRET="your_jwt_secret_key_change_in_production_min_32_chars_please_change_this"
export PORT=4001
export NODE_ENV=production

echo "✅ Đã export env variables"

# Start PM2
pm2 start ecosystem.config.js
pm2 save

# 5. Kiểm tra
echo ""
echo "5️⃣  Kiểm tra (đợi 5 giây)..."
sleep 5

echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api

echo ""
echo "📝 Logs (last 25 lines):"
pm2 logs asset-rmg-api --lines 25 --nostream

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn lỗi, kiểm tra:"
echo "   1. File .env: ls -la /var/www/asset-rmg/backend/.env"
echo "   2. Test load: cd /var/www/asset-rmg/backend && node -e \"require('dotenv').config(); console.log(process.env.DATABASE_URL)\""
echo "   3. PM2 env: pm2 describe asset-rmg-api | grep DATABASE_URL"
