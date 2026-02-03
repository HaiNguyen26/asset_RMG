#!/bin/bash
# Script fix Nginx path rewrite để strip /asset_rmg prefix

set -e

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fix Nginx Path Rewrite"
echo "========================="

# Backup
echo ""
echo "💾 Backup file config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Kiểm tra config hiện tại
echo ""
echo "📋 Config hiện tại cho /asset_rmg/api:"
sudo grep -A 5 "location /asset_rmg/api" "$NGINX_CONFIG" | head -10

# Vấn đề: proxy_pass không có rewrite, nên path /asset_rmg/api/auth/login
# được forward thành http://localhost:4001/asset_rmg/api/auth/login
# Nhưng backend chỉ có route /api/auth/login

# Giải pháp: Dùng rewrite để strip /asset_rmg prefix

echo ""
echo "🔧 Đang fix path rewrite..."

# Tìm và thay thế location /asset_rmg/api block
python3 << PYTHON_SCRIPT
import re
import sys

config_file = "$NGINX_CONFIG"

# Đọc file
with open(config_file, 'r') as f:
    content = f.read()

# Pattern để tìm location /asset_rmg/api block
pattern = r'(location /asset_rmg/api \{)(.*?)(\n\s*\})'

def fix_location(match):
    location_line = match.group(1)
    block_content = match.group(2)
    closing_brace = match.group(3)
    
    # Kiểm tra xem đã có rewrite chưa
    if 'rewrite' in block_content:
        print("⚠️  Đã có rewrite, giữ nguyên")
        return match.group(0)
    
    # Tạo config mới với rewrite
    # Rewrite /asset_rmg/api/... thành /api/...
    new_block = f"""{location_line}
        rewrite ^/asset_rmg/api(.*)$ /api$1 break;
        proxy_pass http://localhost:4001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    {closing_brace}"""
    
    return new_block

# Replace
new_content = re.sub(pattern, fix_location, content, flags=re.DOTALL)

# Ghi lại file
with open(config_file, 'w') as f:
    f.write(new_content)

print("✅ Đã thêm rewrite rule")
PYTHON_SCRIPT

if [ $? -ne 0 ]; then
    echo "❌ Không thể fix tự động"
    echo "   Khôi phục từ backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    exit 1
fi

# Test config
echo ""
echo "🧪 Test Nginx config..."
if sudo nginx -t; then
    echo "✅ Nginx config hợp lệ"
    
    echo ""
    echo "📋 Config sau khi fix:"
    sudo grep -A 25 "location /asset_rmg/api" "$NGINX_CONFIG" | head -30
    
    echo ""
    read -p "Bạn có muốn reload Nginx không? (y/n): " reload
    
    if [ "$reload" = "y" ] || [ "$reload" = "Y" ]; then
        sudo systemctl reload nginx
        echo "✅ Nginx đã reload"
        
        echo ""
        echo "🧪 Test API sau khi fix:"
        sleep 1
        
        # Test API
        API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/asset_rmg/api/auth/login \
          -H "Content-Type: application/json" -d '{"employeesCode":"test","password":"test"}' 2>/dev/null || echo "000")
        
        echo "   HTTP Response: $API_RESPONSE"
        
        if [ "$API_RESPONSE" = "401" ] || [ "$API_RESPONSE" = "400" ]; then
            echo "   ✅ API đang phản hồi!"
            
            # Test với verbose để xem path
            echo ""
            echo "🧪 Test với verbose để xem path:"
            curl -v -X POST http://localhost/asset_rmg/api/auth/login \
              -H "Content-Type: application/json" \
              -d '{"employeesCode":"test","password":"test"}' 2>&1 | grep -E "POST|Host|HTTP" | head -5
        elif [ "$API_RESPONSE" = "404" ]; then
            echo "   ❌ API vẫn 404"
            echo "   Kiểm tra backend route:"
            echo "   curl http://localhost:4001/api/auth/login"
        else
            echo "   ⚠️  Response: HTTP $API_RESPONSE"
        fi
    fi
else
    echo "❌ Nginx config không hợp lệ!"
    echo "   Khôi phục từ backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    exit 1
fi

echo ""
echo "✅ Hoàn thành!"
