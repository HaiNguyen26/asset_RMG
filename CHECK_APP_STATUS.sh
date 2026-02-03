#!/bin/bash
# Script kiểm tra toàn diện trạng thái app

cd /var/www/asset-rmg

echo "🔍 Kiểm tra trạng thái ứng dụng..."
echo "===================================="

# 1. Kiểm tra PM2
echo ""
echo "1️⃣  PM2 Status:"
pm2 status | grep asset-rmg-api || echo "❌ PM2 process không chạy"

# 2. Kiểm tra Backend
echo ""
echo "2️⃣  Backend API Test:"
echo "   Testing: http://localhost:4001/api/departments"
DEPARTMENTS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4001/api/departments)
if [ "$DEPARTMENTS_RESPONSE" = "200" ]; then
    echo "   ✅ Backend đang chạy (HTTP $DEPARTMENTS_RESPONSE)"
else
    echo "   ❌ Backend không phản hồi (HTTP $DEPARTMENTS_RESPONSE)"
fi

# 3. Kiểm tra Frontend
echo ""
echo "3️⃣  Frontend Files:"
if [ -f frontend/dist/index.html ]; then
    echo "   ✅ Frontend đã build (index.html tồn tại)"
    ls -lh frontend/dist/index.html | awk '{print "   Size: " $5}'
else
    echo "   ❌ Frontend chưa build (index.html không tồn tại)"
fi

# 4. Kiểm tra Nginx
echo ""
echo "4️⃣  Nginx Status:"
if systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx đang chạy"
    
    # Test Nginx config
    if nginx -t 2>/dev/null; then
        echo "   ✅ Nginx config hợp lệ"
    else
        echo "   ⚠️  Nginx config có vấn đề"
    fi
    
    # Test qua Nginx
    echo ""
    echo "   Testing: http://localhost/asset_rmg/api/departments"
    NGINX_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/api/departments)
    if [ "$NGINX_RESPONSE" = "200" ]; then
        echo "   ✅ Nginx proxy hoạt động (HTTP $NGINX_RESPONSE)"
    else
        echo "   ❌ Nginx proxy không hoạt động (HTTP $NGINX_RESPONSE)"
    fi
else
    echo "   ❌ Nginx không chạy"
fi

# 5. Kiểm tra Database
echo ""
echo "5️⃣  Database Connection:"
cd backend
if node -e "require('dotenv').config(); const { PrismaClient } = require('@prisma/client'); const { Pool } = require('pg'); const { PrismaPg } = require('@prisma/adapter-pg'); const pool = new Pool({ connectionString: process.env.DATABASE_URL }); const adapter = new PrismaPg(pool); const prisma = new PrismaClient({ adapter }); prisma.\$connect().then(() => { console.log('✅ Database connected'); prisma.\$disconnect(); pool.end(); process.exit(0); }).catch(err => { console.error('❌ Database error:', err.message); process.exit(1); });" 2>/dev/null; then
    echo "   ✅ Database connection OK"
else
    echo "   ❌ Database connection failed"
fi

# 6. Tóm tắt
echo ""
echo "=========================================="
echo "📊 TÓM TẮT:"
echo "=========================================="

PM2_RUNNING=$(pm2 list 2>/dev/null | grep -q "asset-rmg-api.*online" && echo "YES" || echo "NO")
BACKEND_OK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4001/api/departments 2>/dev/null | grep -q "200" && echo "YES" || echo "NO")
FRONTEND_OK=$([ -f frontend/dist/index.html ] && echo "YES" || echo "NO")
NGINX_OK=$(systemctl is-active --quiet nginx 2>/dev/null && echo "YES" || echo "NO")

echo "PM2:        $PM2_RUNNING"
echo "Backend:    $BACKEND_OK"
echo "Frontend:   $FRONTEND_OK"
echo "Nginx:      $NGINX_OK"

echo ""
if [ "$PM2_RUNNING" = "YES" ] && [ "$BACKEND_OK" = "YES" ] && [ "$FRONTEND_OK" = "YES" ] && [ "$NGINX_OK" = "YES" ]; then
    echo "✅ Ứng dụng đang chạy tốt!"
    echo ""
    echo "🌐 Truy cập:"
    echo "   Frontend: http://27.71.16.15/asset_rmg"
    echo "   Backend:  http://27.71.16.15/asset_rmg/api"
else
    echo "⚠️  Có một số vấn đề cần kiểm tra"
    echo ""
    echo "💡 Xem chi tiết ở trên để biết phần nào cần fix"
fi
