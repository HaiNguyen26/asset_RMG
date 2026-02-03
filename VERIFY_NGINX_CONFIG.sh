#!/bin/bash
# Script verify Nginx config và test endpoints

echo "🔍 Verify Nginx Config và Test Endpoints"
echo "=========================================="

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

# 1. Test Nginx config syntax
echo ""
echo "1️⃣  Test Nginx Config Syntax..."
if sudo nginx -t; then
    echo "✅ Nginx config hợp lệ"
else
    echo "❌ Nginx config có lỗi!"
    exit 1
fi

# 2. Kiểm tra config chi tiết
echo ""
echo "2️⃣  Kiểm tra Config Chi Tiết..."
echo ""

echo "📍 Location /asset_rmg/api:"
sudo grep -A 25 "location /asset_rmg/api" "$NGINX_CONFIG" | head -30

echo ""
echo "📍 Location /asset_rmg (frontend):"
sudo grep -A 20 "location /asset_rmg {" "$NGINX_CONFIG" | grep -v "location /asset_rmg/api" | head -25

# 3. Kiểm tra thứ tự location blocks
echo ""
echo "3️⃣  Kiểm tra Thứ Tự Location Blocks..."
ASSET_LINE=$(sudo grep -n "location /asset_rmg {" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
ROOT_LINE=$(sudo grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -n "$ASSET_LINE" ] && [ -n "$ROOT_LINE" ]; then
    if [ "$ASSET_LINE" -lt "$ROOT_LINE" ]; then
        echo "✅ Thứ tự đúng: location /asset_rmg (dòng $ASSET_LINE) trước location / (dòng $ROOT_LINE)"
    else
        echo "❌ Thứ tự SAI: location / (dòng $ROOT_LINE) trước location /asset_rmg (dòng $ASSET_LINE)"
    fi
fi

# 4. Kiểm tra backend đang chạy
echo ""
echo "4️⃣  Kiểm tra Backend..."
if pm2 list | grep -q "asset-rmg-api"; then
    PM2_STATUS=$(pm2 jlist | grep -A 5 "asset-rmg-api" | grep "pm2_env.status" | cut -d'"' -f4)
    if [ "$PM2_STATUS" = "online" ]; then
        echo "✅ Backend đang online"
    else
        echo "❌ Backend không online"
    fi
else
    echo "❌ Backend process không tìm thấy"
fi

# 5. Test endpoints
echo ""
echo "5️⃣  Test Endpoints..."
echo ""

# Test API
echo "🧪 Test API: POST /asset_rmg/api/auth/login"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")

echo "   HTTP Response: $API_RESPONSE"
if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "   ✅ API đang phản hồi (credentials sai là bình thường)"
elif [ "$API_RESPONSE" = "404" ]; then
    echo "   ❌ API trả về 404 - Route không tìm thấy"
elif [ "$API_RESPONSE" = "502" ] || [ "$API_RESPONSE" = "503" ]; then
    echo "   ❌ API trả về $API_RESPONSE - Backend không kết nối được"
else
    echo "   ⚠️  Response: HTTP $API_RESPONSE"
fi

# Test Frontend
echo ""
echo "🧪 Test Frontend: GET /asset_rmg"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg 2>/dev/null || echo "000")
REDIRECT_URL=$(curl -s -I http://localhost/asset_rmg 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")

echo "   HTTP Response: $FRONTEND_RESPONSE"
if [ -n "$REDIRECT_URL" ]; then
    echo "   Redirect đến: $REDIRECT_URL"
    if echo "$REDIRECT_URL" | grep -q "/asset_rmg"; then
        echo "   ✅ Redirect có base path đúng"
    else
        echo "   ⚠️  Redirect không có base path"
    fi
fi

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "   ✅ Frontend đang phản hồi"
elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
    echo "   ⚠️  Frontend redirect (HTTP $FRONTEND_RESPONSE)"
else
    echo "   ⚠️  Response: HTTP $FRONTEND_RESPONSE"
fi

# Test Logo
echo ""
echo "🧪 Test Logo: GET /asset_rmg/RMG-logo.jpg"
LOGO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/RMG-logo.jpg 2>/dev/null || echo "000")
echo "   HTTP Response: $LOGO_RESPONSE"

if [ "$LOGO_RESPONSE" = "200" ]; then
    echo "   ✅ Logo có thể truy cập được"
else
    echo "   ⚠️  Logo không thể truy cập (HTTP $LOGO_RESPONSE)"
fi

# 6. Kiểm tra file frontend
echo ""
echo "6️⃣  Kiểm tra Frontend Files..."
FRONTEND_DIST="/var/www/asset-rmg/frontend/dist"

if [ -d "$FRONTEND_DIST" ]; then
    echo "✅ Thư mục dist tồn tại"
    
    if [ -f "$FRONTEND_DIST/index.html" ]; then
        echo "✅ File index.html tồn tại"
    else
        echo "❌ File index.html KHÔNG tồn tại"
    fi
    
    if [ -f "$FRONTEND_DIST/RMG-logo.jpg" ]; then
        echo "✅ Logo file tồn tại trong dist/"
    else
        echo "⚠️  Logo file KHÔNG tồn tại trong dist/"
    fi
else
    echo "❌ Thư mục dist KHÔNG tồn tại"
fi

# Tóm tắt
echo ""
echo "=========================================="
echo "📋 Tóm Tắt"
echo "=========================================="

ISSUES=0

if [ "$API_RESPONSE" != "401" ] && [ "$API_RESPONSE" != "400" ]; then
    echo "❌ API: HTTP $API_RESPONSE"
    ISSUES=$((ISSUES + 1))
else
    echo "✅ API: OK"
fi

if [ "$FRONTEND_RESPONSE" != "200" ]; then
    echo "❌ Frontend: HTTP $FRONTEND_RESPONSE"
    ISSUES=$((ISSUES + 1))
else
    echo "✅ Frontend: OK"
fi

if [ "$LOGO_RESPONSE" != "200" ]; then
    echo "⚠️  Logo: HTTP $LOGO_RESPONSE"
else
    echo "✅ Logo: OK"
fi

if [ $ISSUES -eq 0 ]; then
    echo ""
    echo "🎉 Tất cả đều OK!"
    echo ""
    echo "🌐 Truy cập ứng dụng:"
    echo "   http://27.71.16.15/asset_rmg"
else
    echo ""
    echo "⚠️  Có $ISSUES vấn đề cần fix"
    echo ""
    echo "🔧 Debug commands:"
    echo "   pm2 logs asset-rmg-api --lines 50"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo "   curl -v http://localhost/asset_rmg/api/auth/login"
fi
