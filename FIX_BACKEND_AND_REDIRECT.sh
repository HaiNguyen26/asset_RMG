#!/bin/bash
# Script fix backend không chạy và frontend redirect typo

set -e

echo "🔧 Fix Backend và Frontend Redirect"
echo "===================================="

PROJECT_PATH="/var/www/asset-rmg"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

cd "$PROJECT_PATH"

# ============================================
# 1. FIX BACKEND
# ============================================
echo ""
echo "1️⃣  Fix Backend..."
echo "----------------------------------------"

# Kiểm tra PM2
if pm2 list | grep -q "asset-rmg-api"; then
    PM2_STATUS=$(pm2 jlist | grep -A 5 "asset-rmg-api" | grep "pm2_env.status" | cut -d'"' -f4)
    
    if [ "$PM2_STATUS" = "online" ]; then
        echo "✅ Backend đang online"
    else
        echo "⚠️  Backend không online, đang restart..."
        pm2 restart asset-rmg-api
        sleep 3
        
        # Kiểm tra lại
        PM2_STATUS=$(pm2 jlist | grep -A 5 "asset-rmg-api" | grep "pm2_env.status" | cut -d'"' -f4)
        if [ "$PM2_STATUS" = "online" ]; then
            echo "✅ Backend đã restart thành công"
        else
            echo "❌ Backend vẫn không online"
            echo "   Xem logs:"
            pm2 logs asset-rmg-api --lines 20 --nostream
        fi
    fi
else
    echo "⚠️  PM2 process chưa có, đang start..."
    
    # Kiểm tra file build
    if [ ! -f "$BACKEND_PATH/dist/src/main.js" ]; then
        echo "❌ File build không tồn tại!"
        echo "   Đang build backend..."
        
        cd "$BACKEND_PATH"
        
        # Kiểm tra .env
        if [ ! -f .env ]; then
            echo "⚠️  File .env không tồn tại, tạo mới..."
            cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
        fi
        
        # Build
        npm install
        npx prisma generate
        npm run build
        
        if [ ! -f dist/src/main.js ]; then
            echo "❌ Build failed!"
            exit 1
        fi
        
        echo "✅ Build thành công"
        cd "$PROJECT_PATH"
    fi
    
    # Start PM2
    pm2 start ecosystem.config.js
    pm2 save
    
    sleep 3
    
    # Kiểm tra
    if pm2 list | grep -q "asset-rmg-api"; then
        PM2_STATUS=$(pm2 jlist | grep -A 5 "asset-rmg-api" | grep "pm2_env.status" | cut -d'"' -f4)
        if [ "$PM2_STATUS" = "online" ]; then
            echo "✅ Backend đã start thành công"
        else
            echo "❌ Backend start failed"
            pm2 logs asset-rmg-api --lines 20 --nostream
            exit 1
        fi
    else
        echo "❌ Không thể start backend"
        exit 1
    fi
fi

# Test backend trực tiếp
echo ""
echo "🧪 Test backend trực tiếp..."
BACKEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "000")

if [ "$BACKEND_TEST" = "400" ] || [ "$BACKEND_TEST" = "401" ] || [ "$BACKEND_TEST" = "405" ]; then
    echo "✅ Backend đang phản hồi (HTTP $BACKEND_TEST)"
else
    echo "⚠️  Backend response: HTTP $BACKEND_TEST"
    echo "   Xem logs:"
    pm2 logs asset-rmg-api --lines 10 --nostream
fi

# ============================================
# 2. FIX FRONTEND REDIRECT TYPO
# ============================================
echo ""
echo "2️⃣  Fix Frontend Redirect Typo..."
echo "----------------------------------------"

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

# Kiểm tra có typo asset_rmq không
if sudo grep -q "asset_rmq\|asset-rmq" "$NGINX_CONFIG"; then
    echo "⚠️  PHÁT HIỆN TYPO: asset_rmq trong Nginx config"
    
    # Backup
    BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
    echo "✅ Đã backup: $BACKUP_FILE"
    
    # Fix typo
    echo "🔧 Đang fix typo..."
    sudo sed -i 's/asset_rmq/asset_rmg/g' "$NGINX_CONFIG"
    sudo sed -i 's/asset-rmq/asset-rmg/g' "$NGINX_CONFIG"
    
    echo "✅ Đã fix typo"
    
    # Test config
    if sudo nginx -t; then
        echo "✅ Nginx config hợp lệ"
        sudo systemctl reload nginx
        echo "✅ Nginx đã reload"
    else
        echo "❌ Nginx config không hợp lệ sau khi fix"
        echo "   Khôi phục từ backup..."
        sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
        exit 1
    fi
else
    echo "✅ Không có typo trong Nginx config"
fi

# Kiểm tra frontend build có typo không
echo ""
echo "🔍 Kiểm tra frontend build..."
if [ -f "$FRONTEND_PATH/dist/index.html" ]; then
    if grep -q "asset_rmq\|asset-rmq" "$FRONTEND_PATH/dist/index.html" 2>/dev/null || \
       grep -r "asset_rmq\|asset-rmq" "$FRONTEND_PATH/dist/assets" 2>/dev/null | head -1 > /dev/null; then
        echo "⚠️  PHÁT HIỆN TYPO trong frontend build"
        echo "   Cần rebuild frontend..."
        
        cd "$FRONTEND_PATH"
        export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
        npm run build
        
        echo "✅ Frontend đã rebuild"
        cd "$PROJECT_PATH"
    else
        echo "✅ Frontend build không có typo"
    fi
else
    echo "⚠️  Frontend chưa build"
fi

# ============================================
# 3. TEST SAU KHI FIX
# ============================================
echo ""
echo "3️⃣  Test Sau Khi Fix..."
echo "----------------------------------------"

# Test API
echo "🧪 Test API:"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")

echo "   HTTP Response: $API_RESPONSE"
if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "   ✅ API đang phản hồi!"
else
    echo "   ⚠️  API response: HTTP $API_RESPONSE"
fi

# Test Frontend
echo ""
echo "🧪 Test Frontend:"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg 2>/dev/null || echo "000")
REDIRECT_URL=$(curl -s -I http://localhost/asset_rmg 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")

echo "   HTTP Response: $FRONTEND_RESPONSE"
if [ -n "$REDIRECT_URL" ]; then
    echo "   Redirect đến: $REDIRECT_URL"
    if echo "$REDIRECT_URL" | grep -q "asset_rmg"; then
        echo "   ✅ Redirect có base path đúng (asset_rmg)"
    elif echo "$REDIRECT_URL" | grep -q "asset_rmq"; then
        echo "   ❌ Redirect vẫn có typo (asset_rmq)"
    else
        echo "   ⚠️  Redirect không có base path"
    fi
fi

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "   ✅ Frontend đang phản hồi!"
elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
    echo "   ⚠️  Frontend vẫn redirect (HTTP $FRONTEND_RESPONSE)"
else
    echo "   ⚠️  Response: HTTP $FRONTEND_RESPONSE"
fi

# ============================================
# TÓM TẮT
# ============================================
echo ""
echo "=========================================="
echo "📋 Tóm Tắt"
echo "=========================================="

if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "✅ API: OK"
else
    echo "❌ API: HTTP $API_RESPONSE"
fi

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend: OK"
else
    echo "⚠️  Frontend: HTTP $FRONTEND_RESPONSE"
fi

echo ""
echo "🌐 Truy cập: http://27.71.16.15/asset_rmg"
echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api || echo "   Process không tìm thấy"
