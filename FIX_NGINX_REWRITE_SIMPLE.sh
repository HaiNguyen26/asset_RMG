#!/bin/bash
# Script đơn giản để thêm rewrite rule vào Nginx config

set -e

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fix Nginx Path Rewrite - Simple Method"
echo "=========================================="

# Backup
echo ""
echo "💾 Backup file config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Kiểm tra đã có rewrite chưa
echo ""
echo "📋 Kiểm tra config hiện tại..."
if sudo grep -A 2 "location /asset_rmg/api" "$NGINX_CONFIG" | grep -q "rewrite"; then
    echo "✅ Đã có rewrite rule"
    echo ""
    echo "Config hiện tại:"
    sudo grep -A 3 "location /asset_rmg/api" "$NGINX_CONFIG" | head -5
    echo ""
    read -p "Bạn có muốn thêm lại không? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Đã hủy"
        exit 0
    fi
fi

# Tìm dòng location /asset_rmg/api
LOCATION_LINE=$(sudo grep -n "location /asset_rmg/api" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$LOCATION_LINE" ]; then
    echo "❌ Không tìm thấy location /asset_rmg/api"
    exit 1
fi

echo "📍 Tìm thấy location /asset_rmg/api tại dòng $LOCATION_LINE"

# Kiểm tra dòng tiếp theo có phải là { không
NEXT_LINE=$(sudo sed -n "$((LOCATION_LINE+1))p" "$NGINX_CONFIG")

if echo "$NEXT_LINE" | grep -q "{"; then
    # Dòng tiếp theo là {, insert rewrite sau dòng đó
    INSERT_LINE=$((LOCATION_LINE + 1))
else
    # Dòng hiện tại có {, insert rewrite sau dòng hiện tại
    INSERT_LINE=$LOCATION_LINE
fi

echo "📍 Sẽ thêm rewrite rule sau dòng $INSERT_LINE"

# Kiểm tra đã có rewrite chưa (kiểm tra kỹ hơn)
if sudo sed -n "${LOCATION_LINE},$((LOCATION_LINE+10))p" "$NGINX_CONFIG" | grep -q "rewrite.*asset_rmg/api"; then
    echo "⚠️  Đã có rewrite rule, bỏ qua"
else
    # Thêm rewrite rule
    echo "➕ Đang thêm rewrite rule..."
    
    # Tạo file temp với rewrite rule
    REWRITE_LINE="        rewrite ^/asset_rmg/api(.*)$ /api\$1 break;"
    
    # Insert sau dòng INSERT_LINE
    sudo sed -i "${INSERT_LINE}a\\${REWRITE_LINE}" "$NGINX_CONFIG"
    
    echo "✅ Đã thêm rewrite rule"
fi

# Hiển thị config sau khi thêm
echo ""
echo "📋 Config sau khi thêm (dòng $LOCATION_LINE-$((LOCATION_LINE+5))):"
sudo sed -n "${LOCATION_LINE},$((LOCATION_LINE+5))p" "$NGINX_CONFIG"

# Test config
echo ""
echo "🧪 Test Nginx config..."
if sudo nginx -t; then
    echo "✅ Nginx config hợp lệ"
    
    echo ""
    read -p "Bạn có muốn reload Nginx không? (y/n): " reload
    
    if [ "$reload" = "y" ] || [ "$reload" = "Y" ]; then
        sudo systemctl reload nginx
        echo "✅ Nginx đã reload"
        
        echo ""
        echo "🧪 Test API sau khi fix:"
        sleep 1
        
        API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
          -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")
        
        echo "   HTTP Response: $API_RESPONSE"
        
        if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
            echo "   ✅ API đang phản hồi!"
        elif [ "$API_RESPONSE" = "404" ]; then
            echo "   ❌ API vẫn 404"
            echo "   Kiểm tra:"
            echo "   1. Backend route: curl http://localhost:4001/api/auth/login"
            echo "   2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
        else
            echo "   ⚠️  Response: HTTP $API_RESPONSE"
        fi
    fi
else
    echo "❌ Nginx config không hợp lệ!"
    echo "   Khôi phục từ backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    
    echo ""
    echo "⚠️  Vui lòng fix thủ công:"
    echo "   1. Mở file: sudo nano $NGINX_CONFIG"
    echo "   2. Tìm dòng: location /asset_rmg/api {"
    echo "   3. Thêm dòng này ngay sau dòng mở ngoặc { :"
    echo "      rewrite ^/asset_rmg/api(.*)$ /api\$1 break;"
    echo "   4. Test: sudo nginx -t"
    echo "   5. Reload: sudo systemctl reload nginx"
    exit 1
fi

echo ""
echo "✅ Hoàn thành!"
