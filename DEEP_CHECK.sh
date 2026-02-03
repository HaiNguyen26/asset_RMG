#!/bin/bash
# Script kiểm tra chi tiết để tìm nguyên nhân lỗi

echo "🔍 Kiểm Tra Chi Tiết - Tìm Nguyên Nhân Lỗi"
echo "============================================="

PROJECT_PATH="/var/www/asset-rmg"
NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

# ============================================
# 1. KIỂM TRA NGINX CONFIG CHI TIẾT
# ============================================
echo ""
echo "1️⃣  Kiểm tra Nginx Config chi tiết..."
echo "----------------------------------------"

# Kiểm tra location blocks và thứ tự
echo "📍 Location blocks trong config:"
sudo grep -n "location" "$NGINX_CONFIG" | head -10

echo ""
echo "📍 Chi tiết location /asset_rmg:"
sudo grep -A 15 "location /asset_rmg" "$NGINX_CONFIG" | head -20

# Kiểm tra thứ tự
ASSET_LINE=$(sudo grep -n "location /asset_rmg" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
ROOT_LINE=$(sudo grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -n "$ASSET_LINE" ] && [ -n "$ROOT_LINE" ]; then
    if [ "$ASSET_LINE" -lt "$ROOT_LINE" ]; then
        echo "✅ Thứ tự đúng: location /asset_rmg (dòng $ASSET_LINE) trước location / (dòng $ROOT_LINE)"
    else
        echo "❌ Thứ tự SAI: location / (dòng $ROOT_LINE) trước location /asset_rmg (dòng $ASSET_LINE)"
        echo "   Cần đổi thứ tự để /asset_rmg được match trước!"
    fi
fi

# Kiểm tra proxy_pass
echo ""
echo "📍 Proxy pass config:"
PROXY_PASS=$(sudo grep -A 2 "location /asset_rmg/api" "$NGINX_CONFIG" | grep "proxy_pass" | awk '{print $2}' | tr -d ';')
echo "   proxy_pass: $PROXY_PASS"

# Kiểm tra alias
echo ""
echo "📍 Frontend alias config:"
ALIAS_PATH=$(sudo grep -A 2 "location /asset_rmg {" "$NGINX_CONFIG" | grep "alias" | awk '{print $2}' | tr -d ';')
echo "   alias: $ALIAS_PATH"

if [ -n "$ALIAS_PATH" ]; then
    if [ -d "$ALIAS_PATH" ]; then
        echo "   ✅ Thư mục tồn tại"
        if [ -f "$ALIAS_PATH/index.html" ]; then
            echo "   ✅ File index.html tồn tại"
        else
            echo "   ❌ File index.html KHÔNG tồn tại!"
        fi
    else
        echo "   ❌ Thư mục KHÔNG tồn tại!"
    fi
fi

# ============================================
# 2. KIỂM TRA BACKEND
# ============================================
echo ""
echo "2️⃣  Kiểm tra Backend..."
echo "----------------------------------------"

# PM2 status
echo "📊 PM2 Status:"
pm2 status | grep asset-rmg-api || echo "   ⚠️  Process không tìm thấy"

# Test backend trực tiếp
echo ""
echo "🧪 Test backend trực tiếp (port 4001):"
BACKEND_DIRECT=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "000")

echo "   HTTP Response: $BACKEND_DIRECT"
if [ "$BACKEND_DIRECT" = "400" ] || [ "$BACKEND_DIRECT" = "401" ] || [ "$BACKEND_DIRECT" = "405" ]; then
    echo "   ✅ Backend đang phản hồi"
else
    echo "   ❌ Backend KHÔNG phản hồi!"
    echo "   Xem logs:"
    pm2 logs asset-rmg-api --lines 10 --nostream 2>/dev/null || echo "   Không có logs"
fi

# Kiểm tra port
echo ""
echo "🔌 Kiểm tra port 4001:"
if netstat -tlnp 2>/dev/null | grep -q ":4001" || ss -tlnp 2>/dev/null | grep -q ":4001"; then
    echo "   ✅ Port 4001 đang được sử dụng"
    netstat -tlnp 2>/dev/null | grep ":4001" || ss -tlnp 2>/dev/null | grep ":4001"
else
    echo "   ❌ Port 4001 KHÔNG được sử dụng!"
fi

# ============================================
# 3. KIỂM TRA FRONTEND
# ============================================
echo ""
echo "3️⃣  Kiểm tra Frontend..."
echo "----------------------------------------"

FRONTEND_DIST="/var/www/asset-rmg/frontend/dist"

if [ -d "$FRONTEND_DIST" ]; then
    echo "✅ Thư mục dist tồn tại"
    
    # Kiểm tra index.html
    if [ -f "$FRONTEND_DIST/index.html" ]; then
        echo "✅ File index.html tồn tại"
        
        # Kiểm tra base path trong HTML
        echo ""
        echo "📍 Base path trong HTML:"
        grep -i "base\|asset_rmg" "$FRONTEND_DIST/index.html" | head -3 || echo "   Không tìm thấy base tag"
        
        # Kiểm tra basename trong JS
        echo ""
        echo "📍 Basename trong JS files:"
        if ls "$FRONTEND_DIST/assets"/*.js 1> /dev/null 2>&1; then
            grep -h "basename\|asset_rmg" "$FRONTEND_DIST/assets"/*.js 2>/dev/null | head -2 || echo "   Không tìm thấy basename"
        fi
    else
        echo "❌ File index.html KHÔNG tồn tại!"
    fi
    
    # Kiểm tra logo
    echo ""
    echo "📍 Logo file:"
    if [ -f "$FRONTEND_DIST/RMG-logo.jpg" ]; then
        echo "   ✅ Logo tồn tại trong dist/"
    else
        echo "   ❌ Logo KHÔNG tồn tại trong dist/"
        echo "   Kiểm tra public/:"
        ls -la /var/www/asset-rmg/frontend/public/RMG-logo.jpg 2>/dev/null || echo "   Logo cũng không có trong public/"
    fi
else
    echo "❌ Thư mục dist KHÔNG tồn tại!"
    echo "   Cần build frontend!"
fi

# ============================================
# 4. KIỂM TRA API QUA NGINX
# ============================================
echo ""
echo "4️⃣  Kiểm tra API qua Nginx..."
echo "----------------------------------------"

echo "🧪 Test API endpoint qua Nginx:"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")

echo "   HTTP Response: $API_RESPONSE"

if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
    echo "   ✅ API đang phản hồi (credentials sai là bình thường)"
elif [ "$API_RESPONSE" = "404" ]; then
    echo "   ❌ API trả về 404 - Route không tìm thấy!"
    echo ""
    echo "   Kiểm tra Nginx error log:"
    sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "   Không có error log"
elif [ "$API_RESPONSE" = "502" ] || [ "$API_RESPONSE" = "503" ]; then
    echo "   ❌ API trả về $API_RESPONSE - Backend không kết nối được!"
elif [ "$API_RESPONSE" = "000" ]; then
    echo "   ❌ Không thể kết nối đến server!"
else
    echo "   ⚠️  Response không mong đợi: HTTP $API_RESPONSE"
fi

# ============================================
# 5. KIỂM TRA FRONTEND QUA NGINX
# ============================================
echo ""
echo "5️⃣  Kiểm tra Frontend qua Nginx..."
echo "----------------------------------------"

echo "🧪 Test frontend qua Nginx:"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg 2>/dev/null || echo "000")

echo "   HTTP Response: $FRONTEND_RESPONSE"

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "   ✅ Frontend đang phản hồi"
    
    # Kiểm tra redirect
    REDIRECT_URL=$(curl -s -I http://localhost/asset_rmg 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")
    if [ -n "$REDIRECT_URL" ]; then
        echo "   ⚠️  Có redirect đến: $REDIRECT_URL"
        if echo "$REDIRECT_URL" | grep -q "/asset_rmg"; then
            echo "   ✅ Redirect có base path đúng"
        else
            echo "   ❌ Redirect KHÔNG có base path!"
        fi
    fi
else
    echo "   ❌ Frontend không phản hồi (HTTP $FRONTEND_RESPONSE)"
fi

# ============================================
# 6. KIỂM TRA LOGO
# ============================================
echo ""
echo "6️⃣  Kiểm tra Logo..."
echo "----------------------------------------"

LOGO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/RMG-logo.jpg 2>/dev/null || echo "000")

echo "   HTTP Response: $LOGO_RESPONSE"

if [ "$LOGO_RESPONSE" = "200" ]; then
    echo "   ✅ Logo có thể truy cập được"
else
    echo "   ❌ Logo không thể truy cập (HTTP $LOGO_RESPONSE)"
    echo "   Kiểm tra file:"
    ls -la /var/www/asset-rmg/frontend/dist/RMG-logo.jpg 2>/dev/null || echo "   File không tồn tại"
fi

# ============================================
# TÓM TẮT VÀ KHUYẾN NGHỊ
# ============================================
echo ""
echo "=========================================="
echo "📋 Tóm Tắt và Khuyến Nghị"
echo "=========================================="
echo ""

# Tổng hợp vấn đề
ISSUES=0

if [ "$API_RESPONSE" = "404" ]; then
    echo "❌ VẤN ĐỀ: API trả về 404"
    echo "   → Kiểm tra Nginx config và backend route"
    ISSUES=$((ISSUES + 1))
fi

if [ "$BACKEND_DIRECT" != "400" ] && [ "$BACKEND_DIRECT" != "401" ] && [ "$BACKEND_DIRECT" != "405" ]; then
    echo "❌ VẤN ĐỀ: Backend không phản hồi trực tiếp"
    echo "   → Kiểm tra PM2 và backend logs"
    ISSUES=$((ISSUES + 1))
fi

if [ "$FRONTEND_RESPONSE" != "200" ]; then
    echo "❌ VẤN ĐỀ: Frontend không phản hồi"
    echo "   → Kiểm tra frontend build và Nginx config"
    ISSUES=$((ISSUES + 1))
fi

if [ "$LOGO_RESPONSE" != "200" ]; then
    echo "❌ VẤN ĐỀ: Logo không thể truy cập"
    echo "   → Kiểm tra file logo và Nginx static file serving"
    ISSUES=$((ISSUES + 1))
fi

if [ -n "$ASSET_LINE" ] && [ -n "$ROOT_LINE" ] && [ "$ASSET_LINE" -gt "$ROOT_LINE" ]; then
    echo "❌ VẤN ĐỀ: Thứ tự location blocks sai"
    echo "   → Cần đổi thứ tự: location /asset_rmg phải trước location /"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✅ Không phát hiện vấn đề rõ ràng"
    echo "   Kiểm tra browser cache và network tab trong DevTools"
else
    echo ""
    echo "🔧 Các bước fix:"
    echo "   1. Chạy: sudo ./FIX_ALL_ISSUES.sh"
    echo "   2. Hoặc xem: FIX_ROUTING_AND_API.md"
fi

echo ""
echo "📊 Debug commands:"
echo "   pm2 logs asset-rmg-api --lines 50"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "   curl -v http://localhost/asset_rmg/api/auth/login"
