#!/bin/bash
# Script fix lỗi Login API và Logo

set -e

echo "🔧 Fix Lỗi Login API và Logo"
echo "============================="

PROJECT_PATH="/var/www/asset-rmg"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"

cd "$PROJECT_PATH"

# ============================================
# BƯỚC 1: Pull Code Mới (có fix logo)
# ============================================
echo ""
echo "📥 Bước 1: Pull code mới nhất..."
if git pull origin main; then
    echo "✅ Pull code thành công"
else
    echo "⚠️  Git pull failed, tiếp tục với code hiện tại..."
fi

# ============================================
# BƯỚC 2: Kiểm tra Backend
# ============================================
echo ""
echo "🔍 Bước 2: Kiểm tra Backend..."

# Kiểm tra PM2
if pm2 list | grep -q "asset-rmg-api"; then
    echo "✅ PM2 process đang chạy"
    
    # Kiểm tra status
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

# Test backend trực tiếp
echo ""
echo "🧪 Testing backend API..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:4001/api/auth/login -X POST -H "Content-Type: application/json" -d '{}' | grep -q "40[045]"; then
    echo "✅ Backend đang phản hồi (405/400/404 là bình thường cho POST không có body)"
else
    echo "❌ Backend không phản hồi!"
    echo "   Xem logs:"
    pm2 logs asset-rmg-api --lines 10 --nostream
    exit 1
fi

# ============================================
# BƯỚC 3: Kiểm tra Nginx Config
# ============================================
echo ""
echo "🌐 Bước 3: Kiểm tra Nginx Config..."

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

if sudo grep -q "location /asset_rmg/api" "$NGINX_CONFIG"; then
    echo "✅ Nginx config đã có"
    
    # Kiểm tra proxy_pass
    PROXY_PASS=$(sudo grep -A 2 "location /asset_rmg/api" "$NGINX_CONFIG" | grep "proxy_pass" | awk '{print $2}' | tr -d ';')
    if [ "$PROXY_PASS" = "http://localhost:4001" ]; then
        echo "✅ Proxy pass đúng: $PROXY_PASS"
    else
        echo "⚠️  Proxy pass có thể sai: $PROXY_PASS"
        echo "   Mong đợi: http://localhost:4001"
    fi
else
    echo "❌ Nginx config chưa có!"
    echo "   Đang thêm config..."
    
    if [ -f "$PROJECT_PATH/add-nginx-config.sh" ]; then
        chmod +x "$PROJECT_PATH/add-nginx-config.sh"
        sudo "$PROJECT_PATH/add-nginx-config.sh"
    else
        echo "❌ Không tìm thấy script add-nginx-config.sh"
        echo "   Vui lòng thêm config thủ công (xem FIX_LOGIN_AND_LOGO.md)"
        exit 1
    fi
fi

# ============================================
# BƯỚC 4: Rebuild Frontend
# ============================================
echo ""
echo "🎨 Bước 4: Rebuild Frontend..."

cd "$FRONTEND_PATH"

# Kiểm tra logo file
if [ -f "public/RMG-logo.jpg" ]; then
    echo "✅ Logo file tồn tại"
else
    echo "⚠️  Logo file không tồn tại trong public/"
    echo "   Kiểm tra: ls -la public/"
fi

# Build với đúng API URL
echo "🏗️  Building frontend với API URL..."
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
if [ -f "dist/index.html" ]; then
    echo "✅ Frontend build thành công"
    
    # Kiểm tra logo trong dist
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
# BƯỚC 6: Test
# ============================================
echo ""
echo "🧪 Bước 6: Testing..."

# Test API qua Nginx
echo "Testing API qua Nginx..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"test","password":"test"}')

if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "✅ API đang phản hồi (HTTP $API_RESPONSE - bình thường với credentials sai)"
elif [ "$API_RESPONSE" = "404" ]; then
    echo "❌ API vẫn 404!"
    echo "   Kiểm tra Nginx config và backend logs"
else
    echo "⚠️  API response: HTTP $API_RESPONSE"
fi

# Test logo
echo ""
echo "Testing logo..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/RMG-logo.jpg | grep -q "200"; then
    echo "✅ Logo có thể truy cập được"
else
    echo "⚠️  Logo không thể truy cập (có thể chưa có file)"
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
echo "   pm2 logs asset-rmg-api --lines 20"
echo "   sudo tail -f /var/log/nginx/error.log"
echo ""
echo "🧪 Test API:"
echo "   curl -X POST http://localhost/asset_rmg/api/auth/login \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"employeesCode\":\"IT\",\"password\":\"your_password\"}'"
