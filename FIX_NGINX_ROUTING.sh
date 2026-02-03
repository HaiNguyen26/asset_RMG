#!/bin/bash
# Fix Nginx routing - đảm bảo /asset_rmg trỏ đúng

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

echo "🔧 Fix Nginx routing cho Asset RMG..."
echo "======================================"

# 1. Backup file config
echo ""
echo "1️⃣  Backup file config..."
cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Đã backup"

# 2. Kiểm tra config hiện tại
echo ""
echo "2️⃣  Kiểm tra config hiện tại:"
echo "   Location blocks trong file:"
grep -n "location" "$NGINX_CONFIG" | head -10

# 3. Kiểm tra thứ tự location blocks
echo ""
echo "3️⃣  Kiểm tra thứ tự location blocks..."
LOCATION_ROOT_LINE=$(grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
LOCATION_ASSET_LINE=$(grep -n "location /asset_rmg" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -n "$LOCATION_ASSET_LINE" ] && [ -n "$LOCATION_ROOT_LINE" ]; then
    if [ "$LOCATION_ASSET_LINE" -lt "$LOCATION_ROOT_LINE" ]; then
        echo "✅ Thứ tự đúng: /asset_rmg trước /"
    else
        echo "⚠️  Thứ tự SAI: / trước /asset_rmg"
        echo "   Cần đổi thứ tự để /asset_rmg được match trước"
    fi
fi

# 4. Kiểm tra config Asset RMG có đúng không
echo ""
echo "4️⃣  Kiểm tra config Asset RMG:"
if grep -q "location /asset_rmg/api" "$NGINX_CONFIG" && grep -q "location /asset_rmg {" "$NGINX_CONFIG"; then
    echo "✅ Config Asset RMG đã có"
    
    # Kiểm tra alias path
    ASSET_ALIAS=$(grep -A 2 "location /asset_rmg {" "$NGINX_CONFIG" | grep "alias" | awk '{print $2}' | tr -d ';')
    if [ "$ASSET_ALIAS" = "/var/www/asset-rmg/frontend/dist" ]; then
        echo "✅ Alias path đúng: $ASSET_ALIAS"
    else
        echo "⚠️  Alias path có thể sai: $ASSET_ALIAS"
        echo "   Mong đợi: /var/www/asset-rmg/frontend/dist"
    fi
    
    # Kiểm tra proxy_pass
    PROXY_PASS=$(grep -A 2 "location /asset_rmg/api" "$NGINX_CONFIG" | grep "proxy_pass" | awk '{print $2}' | tr -d ';')
    if [ "$PROXY_PASS" = "http://localhost:4001" ]; then
        echo "✅ Proxy pass đúng: $PROXY_PASS"
    else
        echo "⚠️  Proxy pass có thể sai: $PROXY_PASS"
        echo "   Mong đợi: http://localhost:4001"
    fi
else
    echo "❌ Config Asset RMG CHƯA có hoặc không đầy đủ"
    echo "   Cần thêm config (chạy script add-nginx-config.sh)"
fi

# 5. Test và reload
echo ""
echo "5️⃣  Test và reload Nginx..."
if nginx -t; then
    echo "✅ Config hợp lệ"
    systemctl reload nginx
    echo "✅ Nginx đã reload"
else
    echo "❌ Config không hợp lệ!"
    exit 1
fi

# 6. Test routing
echo ""
echo "6️⃣  Test routing:"
echo "   Testing: http://localhost/asset_rmg/api/departments"
sleep 2
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/asset_rmg/api/departments)
if [ "$RESPONSE" = "200" ]; then
    echo "   ✅ Routing hoạt động (HTTP $RESPONSE)"
else
    echo "   ⚠️  Routing có vấn đề (HTTP $RESPONSE)"
fi

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn trỏ sai, kiểm tra:"
echo "   1. Thứ tự location blocks (location /asset_rmg phải trước location /)"
echo "   2. File frontend/dist/index.html có tồn tại không"
echo "   3. Permissions của thư mục frontend/dist"
