#!/bin/bash
# Script fix PM2 process disabled và các vấn đề còn lại

set -e

echo "🔧 Fix PM2 Disabled và Các Vấn Đề"
echo "==================================="

PROJECT_PATH="/var/www/asset-rmg"

cd "$PROJECT_PATH"

# ============================================
# 1. FIX PM2 DISABLED
# ============================================
echo ""
echo "1️⃣  Fix PM2 Process Disabled..."
echo "----------------------------------------"

# Kiểm tra PM2 process
if pm2 list | grep -q "asset-rmg-api"; then
    PM2_STATUS=$(pm2 jlist | grep -A 10 "asset-rmg-api" | grep -E "pm2_env.status|pm2_env.autorestart" | head -2)
    
    echo "📊 PM2 Status hiện tại:"
    pm2 status | grep asset-rmg-api
    
    # Kiểm tra có disabled không
    if echo "$PM2_STATUS" | grep -q '"autorestart":false' || pm2 status | grep asset-rmg-api | grep -q "disabled"; then
        echo "⚠️  PM2 process bị disabled"
        
        # Delete và start lại
        echo "🔄 Đang delete và start lại..."
        pm2 delete asset-rmg-api 2>/dev/null || true
        
        # Start lại với ecosystem.config.js
        pm2 start ecosystem.config.js
        
        # Enable auto-restart
        pm2 startup
        pm2 save
        
        echo "✅ PM2 process đã được enable"
    else
        echo "✅ PM2 process đã được enable"
    fi
    
    # Kiểm tra lại status
    sleep 2
    echo ""
    echo "📊 PM2 Status sau khi fix:"
    pm2 status | grep asset-rmg-api
    
    # Kiểm tra process có online không
    CURRENT_STATUS=$(pm2 jlist | grep -A 5 "asset-rmg-api" | grep "pm2_env.status" | cut -d'"' -f4)
    if [ "$CURRENT_STATUS" = "online" ]; then
        echo "✅ Process đang online"
    else
        echo "⚠️  Process không online, xem logs:"
        pm2 logs asset-rmg-api --lines 20 --nostream
    fi
else
    echo "⚠️  PM2 process không tìm thấy, đang start..."
    pm2 start ecosystem.config.js
    pm2 startup
    pm2 save
fi

# ============================================
# 2. KIỂM TRA BACKEND ROUTE
# ============================================
echo ""
echo "2️⃣  Kiểm tra Backend Route..."
echo "----------------------------------------"

# Test backend trực tiếp
echo "🧪 Test backend trực tiếp (port 4001):"
BACKEND_DIRECT=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "000")

echo "   HTTP Response: $BACKEND_DIRECT"

if [ "$BACKEND_DIRECT" = "400" ] || [ "$BACKEND_DIRECT" = "401" ] || [ "$BACKEND_DIRECT" = "405" ]; then
    echo "   ✅ Backend đang phản hồi"
    
    # Test với GET để xem route có tồn tại không
    echo ""
    echo "🧪 Test route với GET:"
    BACKEND_GET=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4001/api/auth/login 2>/dev/null || echo "000")
    echo "   HTTP Response: $BACKEND_GET"
    
    if [ "$BACKEND_GET" = "405" ]; then
        echo "   ✅ Route tồn tại (405 Method Not Allowed là bình thường cho GET)"
    elif [ "$BACKEND_GET" = "404" ]; then
        echo "   ❌ Route KHÔNG tồn tại (404)"
        echo "   Kiểm tra backend logs:"
        pm2 logs asset-rmg-api --lines 30 --nostream
    fi
else
    echo "   ❌ Backend không phản hồi"
    echo "   Xem logs:"
    pm2 logs asset-rmg-api --lines 30 --nostream
fi

# ============================================
# 3. KIỂM TRA NGINX PROXY
# ============================================
echo ""
echo "3️⃣  Kiểm tra Nginx Proxy Config..."
echo "----------------------------------------"

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

# Kiểm tra proxy_pass
PROXY_PASS=$(sudo grep -A 2 "location /asset_rmg/api" "$NGINX_CONFIG" | grep "proxy_pass" | awk '{print $2}' | tr -d ';')

echo "📍 Proxy pass: $PROXY_PASS"

if [ "$PROXY_PASS" = "http://localhost:4001" ]; then
    echo "✅ Proxy pass đúng"
else
    echo "⚠️  Proxy pass có thể sai: $PROXY_PASS"
    echo "   Mong đợi: http://localhost:4001"
fi

# Kiểm tra có typo asset_rmq không
if sudo grep -q "asset_rmq\|asset-rmq" "$NGINX_CONFIG"; then
    echo "⚠️  Vẫn còn typo asset_rmq trong Nginx config"
    echo "   Đang fix..."
    
    BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
    
    sudo sed -i 's/asset_rmq/asset_rmg/g' "$NGINX_CONFIG"
    sudo sed -i 's/asset-rmq/asset-rmg/g' "$NGINX_CONFIG"
    
    if sudo nginx -t; then
        sudo systemctl reload nginx
        echo "✅ Đã fix typo và reload Nginx"
    else
        echo "❌ Nginx config không hợp lệ"
        sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    fi
else
    echo "✅ Không có typo trong Nginx config"
fi

# ============================================
# 4. TEST API QUA NGINX
# ============================================
echo ""
echo "4️⃣  Test API qua Nginx..."
echo "----------------------------------------"

echo "🧪 Test API endpoint:"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")

echo "   HTTP Response: $API_RESPONSE"

if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "   ✅ API đang phản hồi!"
elif [ "$API_RESPONSE" = "404" ]; then
    echo "   ❌ API vẫn trả về 404"
    echo ""
    echo "   Kiểm tra Nginx error log:"
    sudo tail -10 /var/log/nginx/error.log | grep -i "asset_rmg\|4001" || echo "   Không có lỗi liên quan"
    echo ""
    echo "   Kiểm tra Nginx access log:"
    sudo tail -5 /var/log/nginx/access.log | grep "asset_rmg" || echo "   Không có request"
elif [ "$API_RESPONSE" = "502" ] || [ "$API_RESPONSE" = "503" ]; then
    echo "   ❌ API trả về $API_RESPONSE - Backend không kết nối được"
    echo "   Kiểm tra backend đang chạy:"
    pm2 status | grep asset-rmg-api
else
    echo "   ⚠️  Response: HTTP $API_RESPONSE"
fi

# Test với verbose để xem chi tiết
echo ""
echo "🧪 Test API với verbose:"
curl -v -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"test","password":"test"}' 2>&1 | grep -E "HTTP|Host|Location|404|401|400" | head -10

# ============================================
# 5. FIX FRONTEND REDIRECT
# ============================================
echo ""
echo "5️⃣  Fix Frontend Redirect..."
echo "----------------------------------------"

# Kiểm tra redirect
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg 2>/dev/null || echo "000")
REDIRECT_URL=$(curl -s -I http://localhost/asset_rmg 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")

echo "   HTTP Response: $FRONTEND_RESPONSE"
if [ -n "$REDIRECT_URL" ]; then
    echo "   Redirect đến: $REDIRECT_URL"
    
    if echo "$REDIRECT_URL" | grep -q "asset_rmq"; then
        echo "   ❌ Redirect vẫn có typo asset_rmq"
        echo "   Kiểm tra frontend build và Nginx config"
        
        # Kiểm tra frontend build
        if grep -r "asset_rmq\|asset-rmq" /var/www/asset-rmg/frontend/dist/ 2>/dev/null | head -1 > /dev/null; then
            echo "   ⚠️  Typo trong frontend build, cần rebuild"
            cd /var/www/asset-rmg/frontend
            export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
            npm run build
            cd "$PROJECT_PATH"
        fi
    elif echo "$REDIRECT_URL" | grep -q "asset_rmg"; then
        echo "   ✅ Redirect có base path đúng"
    fi
fi

# ============================================
# TÓM TẮT
# ============================================
echo ""
echo "=========================================="
echo "📋 Tóm Tắt"
echo "=========================================="

# PM2 Status
echo ""
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api || echo "   Process không tìm thấy"

# API Status
echo ""
if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "✅ API: OK (HTTP $API_RESPONSE)"
else
    echo "❌ API: HTTP $API_RESPONSE"
fi

# Frontend Status
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend: OK"
elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
    echo "⚠️  Frontend: Redirect (HTTP $FRONTEND_RESPONSE)"
else
    echo "❌ Frontend: HTTP $FRONTEND_RESPONSE"
fi

echo ""
echo "🌐 Truy cập: http://27.71.16.15/asset_rmg"
echo ""
echo "🔍 Nếu API vẫn 404, kiểm tra:"
echo "   1. Backend route: curl http://localhost:4001/api/auth/login"
echo "   2. Nginx proxy: sudo tail -f /var/log/nginx/error.log"
echo "   3. PM2 logs: pm2 logs asset-rmg-api --lines 50"
