#!/bin/bash
# Script tổng hợp fix tất cả issues: Routing, API, Logo

set -e

echo "🔧 Fix Tất Cả Issues: Routing, API, Logo"
echo "=========================================="

PROJECT_PATH="/var/www/asset-rmg"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"
NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

cd "$PROJECT_PATH"

# ============================================
# BƯỚC 1: Pull Code Mới
# ============================================
echo ""
echo "📥 Bước 1: Pull code mới nhất..."
if git pull origin main; then
    echo "✅ Pull code thành công"
else
    echo "⚠️  Git pull failed, tiếp tục với code hiện tại..."
fi

# ============================================
# BƯỚC 2: Kiểm tra và Fix Backend
# ============================================
echo ""
echo "🔍 Bước 2: Kiểm tra Backend..."

# Kiểm tra PM2
if pm2 list | grep -q "asset-rmg-api"; then
    PM2_STATUS=$(pm2 jlist | grep -A 5 "asset-rmg-api" | grep "pm2_env.status" | cut -d'"' -f4)
    if [ "$PM2_STATUS" = "online" ]; then
        echo "✅ Backend đang online"
    else
        echo "⚠️  Backend không online, đang restart..."
        pm2 restart asset-rmg-api
        sleep 3
    fi
else
    echo "⚠️  PM2 process chưa có, đang start..."
    pm2 start ecosystem.config.js
    pm2 save
    sleep 3
fi

# Test backend
echo "🧪 Testing backend API..."
BACKEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "000")

if [ "$BACKEND_TEST" = "400" ] || [ "$BACKEND_TEST" = "401" ] || [ "$BACKEND_TEST" = "405" ]; then
    echo "✅ Backend đang phản hồi (HTTP $BACKEND_TEST)"
else
    echo "❌ Backend không phản hồi (HTTP $BACKEND_TEST)"
    echo "   Xem logs:"
    pm2 logs asset-rmg-api --lines 10 --nostream
    echo ""
    echo "⚠️  Tiếp tục với các bước khác..."
fi

# ============================================
# BƯỚC 3: Kiểm tra và Fix Nginx Config
# ============================================
echo ""
echo "🌐 Bước 3: Kiểm tra Nginx Config..."

# Kiểm tra config đã có chưa
if sudo grep -q "location /asset_rmg/api" "$NGINX_CONFIG"; then
    echo "✅ Nginx config đã có"
    
    # Kiểm tra thứ tự location blocks
    ASSET_LINE=$(sudo grep -n "location /asset_rmg" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
    ROOT_LINE=$(sudo grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
    
    if [ -n "$ASSET_LINE" ] && [ -n "$ROOT_LINE" ]; then
        if [ "$ASSET_LINE" -lt "$ROOT_LINE" ]; then
            echo "✅ Thứ tự location blocks đúng (asset_rmg trước /)"
        else
            echo "⚠️  Thứ tự location blocks SAI (cần asset_rmg trước /)"
            echo "   Vui lòng sửa thủ công trong file config"
        fi
    fi
else
    echo "❌ Nginx config chưa có!"
    echo "   Đang thêm config..."
    
    if [ -f "$PROJECT_PATH/add-nginx-config.sh" ]; then
        chmod +x "$PROJECT_PATH/add-nginx-config.sh"
        sudo "$PROJECT_PATH/add-nginx-config.sh"
    else
        echo "❌ Không tìm thấy script add-nginx-config.sh"
        echo "   Vui lòng thêm config thủ công (xem FIX_ROUTING_AND_API.md)"
    fi
fi

# ============================================
# BƯỚC 4: Rebuild Frontend
# ============================================
echo ""
echo "🎨 Bước 4: Rebuild Frontend..."

cd "$FRONTEND_PATH"

# Kiểm tra logo
if [ -f "public/RMG-logo.jpg" ]; then
    echo "✅ Logo file tồn tại"
else
    echo "⚠️  Logo file không tồn tại trong public/"
fi

# Build với đúng API URL
echo "🏗️  Building frontend..."
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
if [ -f "dist/index.html" ]; then
    echo "✅ Frontend build thành công"
    
    # Kiểm tra basename trong build
    if grep -q "basename" dist/index.html 2>/dev/null || grep -r "basename" dist/assets/*.js 2>/dev/null | head -1 > /dev/null; then
        echo "✅ Basename đã được include trong build"
    else
        echo "⚠️  Không tìm thấy basename trong build (có thể bình thường)"
    fi
    
    # Kiểm tra logo
    if [ -f "dist/RMG-logo.jpg" ]; then
        echo "✅ Logo đã được copy vào dist/"
    else
        echo "⚠️  Logo không có trong dist/"
    fi
else
    echo "❌ Frontend build failed!"
    exit 1
fi

# ============================================
# BƯỚC 5: Reload Nginx
# ============================================
echo ""
echo "🔄 Bước 5: Reload Nginx..."

if sudo nginx -t; then
    echo "✅ Nginx config hợp lệ"
    if sudo systemctl reload nginx; then
        echo "✅ Nginx đã reload"
    else
        echo "❌ Nginx reload failed"
        exit 1
    fi
else
    echo "❌ Nginx config không hợp lệ!"
    exit 1
fi

# ============================================
# BƯỚC 6: Testing
# ============================================
echo ""
echo "🧪 Bước 6: Testing..."

# Test API qua Nginx
echo "Testing API qua Nginx..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")

if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "✅ API đang phản hồi (HTTP $API_RESPONSE - bình thường với credentials sai)"
elif [ "$API_RESPONSE" = "404" ]; then
    echo "❌ API vẫn 404!"
    echo "   Kiểm tra Nginx config và backend logs"
else
    echo "⚠️  API response: HTTP $API_RESPONSE"
fi

# Test frontend routing
echo ""
echo "Testing frontend routing..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg 2>/dev/null || echo "000")

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend đang phản hồi (HTTP 200)"
    
    # Kiểm tra có redirect không
    REDIRECT_URL=$(curl -s -I http://localhost/asset_rmg 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")
    if [ -n "$REDIRECT_URL" ]; then
        if echo "$REDIRECT_URL" | grep -q "/asset_rmg"; then
            echo "✅ Redirect có base path đúng"
        else
            echo "⚠️  Redirect không có base path: $REDIRECT_URL"
        fi
    else
        echo "✅ Không có redirect (bình thường)"
    fi
else
    echo "⚠️  Frontend response: HTTP $FRONTEND_RESPONSE"
fi

# Test logo
echo ""
echo "Testing logo..."
LOGO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/RMG-logo.jpg 2>/dev/null || echo "000")

if [ "$LOGO_RESPONSE" = "200" ]; then
    echo "✅ Logo có thể truy cập được"
else
    echo "⚠️  Logo không thể truy cập (HTTP $LOGO_RESPONSE)"
fi

# ============================================
# HOÀN THÀNH
# ============================================
echo ""
echo "=========================================="
echo "✅ Hoàn thành!"
echo "=========================================="
echo ""
echo "🌐 Truy cập ứng dụng:"
echo "   http://27.71.16.15/asset_rmg"
echo ""
echo "📊 Kiểm tra:"
echo "   - Routing: http://27.71.16.15/asset_rmg → phải hiển thị login tại /asset_rmg/login"
echo "   - API: http://27.71.16.15/asset_rmg/api/auth/login"
echo "   - Logo: http://27.71.16.15/asset_rmg/RMG-logo.jpg"
echo ""
echo "🔍 Debug commands:"
echo "   pm2 logs asset-rmg-api --lines 30"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "   curl -X POST http://localhost/asset_rmg/api/auth/login -H 'Content-Type: application/json' -d '{\"employeesCode\":\"IT\",\"password\":\"test\"}'"
