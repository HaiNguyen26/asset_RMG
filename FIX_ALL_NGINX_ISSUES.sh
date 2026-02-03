#!/bin/bash
# Script tổng hợp fix tất cả Nginx issues

set -e

echo "🔧 Fix Tất Cả Nginx Issues"
echo "==========================="

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

# 1. Kiểm tra và fix API proxy
echo ""
echo "1️⃣  Fix API Proxy..."
if [ -f "FIX_NGINX_PROXY.sh" ]; then
    chmod +x FIX_NGINX_PROXY.sh
    sudo ./FIX_NGINX_PROXY.sh
else
    echo "⚠️  Script FIX_NGINX_PROXY.sh không tìm thấy"
fi

# 2. Kiểm tra và fix Frontend redirect
echo ""
echo "2️⃣  Fix Frontend Redirect..."
if [ -f "FIX_FRONTEND_REDIRECT.sh" ]; then
    chmod +x FIX_FRONTEND_REDIRECT.sh
    sudo ./FIX_FRONTEND_REDIRECT.sh
else
    echo "⚠️  Script FIX_FRONTEND_REDIRECT.sh không tìm thấy"
fi

# 3. Kiểm tra thứ tự location blocks
echo ""
echo "3️⃣  Kiểm tra thứ tự location blocks..."
ASSET_LINE=$(sudo grep -n "location /asset_rmg {" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
ROOT_LINE=$(sudo grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -n "$ASSET_LINE" ] && [ -n "$ROOT_LINE" ]; then
    if [ "$ASSET_LINE" -lt "$ROOT_LINE" ]; then
        echo "✅ Thứ tự đúng: location /asset_rmg (dòng $ASSET_LINE) trước location / (dòng $ROOT_LINE)"
    else
        echo "❌ Thứ tự SAI: location / (dòng $ROOT_LINE) trước location /asset_rmg (dòng $ASSET_LINE)"
        echo "   Cần đổi thứ tự thủ công trong file config"
    fi
fi

# 4. Test cuối cùng
echo ""
echo "4️⃣  Test cuối cùng..."
echo ""

# Test API
echo "🧪 Test API:"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")
echo "   HTTP Response: $API_RESPONSE"

# Test Frontend
echo ""
echo "🧪 Test Frontend:"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg 2>/dev/null || echo "000")
REDIRECT_URL=$(curl -s -I http://localhost/asset_rmg 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")
echo "   HTTP Response: $FRONTEND_RESPONSE"
if [ -n "$REDIRECT_URL" ]; then
    echo "   Redirect: $REDIRECT_URL"
fi

# Test Logo
echo ""
echo "🧪 Test Logo:"
LOGO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/RMG-logo.jpg 2>/dev/null || echo "000")
echo "   HTTP Response: $LOGO_RESPONSE"

# Tóm tắt
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
    echo "❌ Frontend: HTTP $FRONTEND_RESPONSE"
fi

if [ "$LOGO_RESPONSE" = "200" ]; then
    echo "✅ Logo: OK"
else
    echo "❌ Logo: HTTP $LOGO_RESPONSE"
fi

echo ""
echo "🌐 Truy cập: http://27.71.16.15/asset_rmg"
