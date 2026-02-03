#!/bin/bash
# Script fix Nginx proxy config cho API

set -e

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fix Nginx Proxy Config cho API"
echo "==================================="

# Backup
echo ""
echo "💾 Backup file config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Kiểm tra config hiện tại
echo ""
echo "📋 Config hiện tại cho /asset_rmg/api:"
sudo grep -A 20 "location /asset_rmg/api" "$NGINX_CONFIG" | head -25

# Kiểm tra proxy_pass
PROXY_PASS=$(sudo grep -A 2 "location /asset_rmg/api" "$NGINX_CONFIG" | grep "proxy_pass" | awk '{print $2}' | tr -d ';')

echo ""
echo "📍 Proxy pass hiện tại: $PROXY_PASS"

# Vấn đề có thể là proxy_pass không có trailing slash hoặc có vấn đề với path rewriting
# Khi proxy_pass không có trailing slash, Nginx sẽ giữ nguyên path
# Khi proxy_pass có trailing slash, Nginx sẽ strip location path

# Fix: Đảm bảo proxy_pass đúng và có rewrite path nếu cần
echo ""
echo "🔧 Đang fix proxy config..."

# Tạo config mới đúng cách
python3 << PYTHON_SCRIPT
import re
import sys

config_file = "$NGINX_CONFIG"

# Đọc file
with open(config_file, 'r') as f:
    content = f.read()

# Tìm và fix location /asset_rmg/api block
pattern = r'(location /asset_rmg/api \{.*?proxy_pass\s+)([^;]+)(.*?\})'

def fix_proxy(match):
    prefix = match.group(1)
    proxy_url = match.group(2).strip()
    suffix = match.group(3)
    
    # Đảm bảo proxy_pass đúng format
    if not proxy_url.startswith('http://'):
        proxy_url = 'http://localhost:4001'
    
    # Nếu proxy_url có trailing slash, cần rewrite
    # Nếu không có trailing slash, giữ nguyên path
    
    # Fix: Không có trailing slash để giữ nguyên path /api/auth/login
    proxy_url = proxy_url.rstrip('/')
    
    # Tạo config đúng
    fixed_config = f"""{prefix}{proxy_url};
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
    {suffix}"""
    
    return fixed_config

# Tìm và replace
new_content = re.sub(pattern, fix_proxy, content, flags=re.DOTALL)

# Ghi lại file
with open(config_file, 'w') as f:
    f.write(new_content)

print("✅ Đã fix proxy config")
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
    sudo grep -A 20 "location /asset_rmg/api" "$NGINX_CONFIG" | head -25
    
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
            echo "   ⚠️  API vẫn 404 - Kiểm tra backend route"
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
