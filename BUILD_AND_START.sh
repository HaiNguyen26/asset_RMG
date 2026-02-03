#!/bin/bash
# Script để build và start ứng dụng trên server

set -e  # Dừng nếu có lỗi

echo "🚀 Bắt đầu build và start ứng dụng..."

# Di chuyển đến thư mục project
cd /var/www/asset-rmg

# 1. Pull code mới nhất (nếu cần)
echo "📥 Pulling code mới nhất..."
git pull origin main || echo "⚠️  Git pull failed hoặc không có thay đổi"

# 2. Build Backend
echo "🔨 Building backend..."
cd backend

# Kiểm tra .env file
if [ ! -f .env ]; then
    echo "⚠️  File .env không tồn tại, tạo file mới..."
    cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
fi

# Cài đặt dependencies
echo "📦 Installing backend dependencies..."
npm install

# Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Chạy migrations
echo "🗄️  Running database migrations..."
npx prisma migrate deploy || echo "⚠️  Migration failed hoặc không có migrations mới"

# Build backend
echo "🏗️  Building backend..."
npm run build

# Kiểm tra build thành công
if [ ! -f dist/main.js ]; then
    echo "❌ Build failed! File dist/main.js không tồn tại"
    exit 1
fi

echo "✅ Backend build thành công!"

# 3. Build Frontend
echo "🎨 Building frontend..."
cd ../frontend

# Cài đặt dependencies
echo "📦 Installing frontend dependencies..."
npm install

# Build frontend với API URL
echo "🏗️  Building frontend..."
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
if [ ! -f dist/index.html ]; then
    echo "❌ Frontend build failed! File dist/index.html không tồn tại"
    exit 1
fi

echo "✅ Frontend build thành công!"

# 4. Start/Restart PM2
echo "🔄 Starting/Restarting PM2..."
cd /var/www/asset-rmg

# Dừng process cũ nếu có
pm2 delete asset-rmg-api 2>/dev/null || true

# Start với ecosystem.config.js
pm2 start ecosystem.config.js

# Lưu PM2 config
pm2 save

echo "✅ PM2 started successfully!"

# 5. Reload Nginx
echo "🔄 Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx || echo "⚠️  Nginx reload failed"

echo ""
echo "🎉 Hoàn thành! Ứng dụng đã được build và start."
echo ""
echo "📊 Kiểm tra status:"
pm2 status
echo ""
echo "📝 Xem logs: pm2 logs asset-rmg-api"
echo "🌐 Truy cập: http://27.71.16.15/asset_rmg"
