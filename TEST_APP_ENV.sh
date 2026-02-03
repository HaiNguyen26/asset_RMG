#!/bin/bash
# Test xem app có nhận được env khi chạy không

cd /var/www/asset-rmg

echo "🧪 Test xem app có nhận được env khi chạy..."
echo "============================================="

# 1. Kiểm tra env trong PM2
echo ""
echo "1️⃣  Env trong PM2:"
pm2 describe asset-rmg-api | grep -A 10 "env:" | head -15

# 2. Test chạy app thủ công với env
echo ""
echo "2️⃣  Test chạy app thủ công với env từ PM2..."
cd backend

# Lấy DATABASE_URL từ PM2
DB_URL=$(pm2 describe asset-rmg-api 2>/dev/null | grep "DATABASE_URL" | awk -F'|' '{print $3}' | xargs)

if [ -z "$DB_URL" ]; then
    echo "⚠️  Không lấy được DATABASE_URL từ PM2"
    DB_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db"
fi

echo "📋 DATABASE_URL từ PM2:"
echo "$DB_URL" | sed 's/:.*@/:****@/g'

# Test chạy với env này
echo ""
echo "3️⃣  Test chạy app với env..."
export DATABASE_URL="$DB_URL"
export JWT_SECRET="your_jwt_secret_key_change_in_production_min_32_chars_please_change_this"
export PORT=4001
export NODE_ENV=production

# Test chỉ load env và check
echo "🧪 Testing env load..."
timeout 5 node -e "
require('dotenv').config();
console.log('DATABASE_URL from dotenv:', process.env.DATABASE_URL ? 'SET (' + process.env.DATABASE_URL.substring(0, 30) + '...)' : 'NOT SET');
console.log('DATABASE_URL from process.env:', process.env.DATABASE_URL ? 'SET' : 'NOT SET');
" 2>&1 || echo "⚠️  Test timeout hoặc có lỗi"

# 4. Kiểm tra working directory của PM2
echo ""
echo "4️⃣  Working directory của PM2:"
pm2 describe asset-rmg-api | grep "cwd\|exec cwd" || echo "⚠️  Không tìm thấy cwd"

# 5. Kiểm tra script path
echo ""
echo "5️⃣  Script path của PM2:"
pm2 describe asset-rmg-api | grep "script path\|script" | head -3

echo ""
echo "✅ Test hoàn thành!"
echo ""
echo "💡 Nếu DATABASE_URL có trong PM2 nhưng app không nhận được:"
echo "   1. Có thể cần restart với --update-env"
echo "   2. Hoặc app đang chạy từ working directory khác"
echo "   3. Hoặc PrismaService đọc env sai cách"
