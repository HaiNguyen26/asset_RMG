#!/bin/bash
# Script fix frontend redirect 301 issue

set -e

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fix Frontend Redirect 301"
echo "============================="

# Backup
echo ""
echo "💾 Backup file config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Kiểm tra config hiện tại
echo ""
echo "📋 Config hiện tại cho /asset_rmg:"
sudo grep -A 15 "location /asset_rmg {" "$NGINX_CONFIG" | head -20

# Vấn đề có thể là:
# 1. try_files không đúng
# 2. alias path không đúng
# 3. Có redirect từ Nginx

echo ""
echo "🔧 Đang fix frontend config..."

# Fix try_files để đảm bảo không redirect
python3 << PYTHON_SCRIPT
import re
import sys

config_file = "$NGINX_CONFIG"

# Đọc file
with open(config_file, 'r') as f:
    content = f.read()

# Tìm location /asset_rmg block (không phải /asset_rmg/api)
pattern = r'(location /asset_rmg \{)(.*?)(location /asset_rmg/api|\n\s*location /|\Z)'

def fix_frontend(match):
    location_line = match.group(1)
    block_content = match.group(2)
    next_location = match.group(3) if match.group(3) else ""
    
    # Kiểm tra xem đã có config đúng chưa
    if 'try_files' in block_content and 'alias' in block_content:
        # Đã có config, chỉ cần đảm bảo try_files đúng
        # Fix try_files để không redirect
        block_content = re.sub(
            r'try_files\s+[^;]+;',
            'try_files $uri $uri/ /asset_rmg/index.html;',
            block_content
        )
        
        # Đảm bảo alias đúng
        block_content = re.sub(
            r'alias\s+[^;]+;',
            'alias /var/www/asset-rmg/frontend/dist;',
            block_content
        )
    else:
        # Chưa có config đầy đủ, thêm mới
        block_content = f"""
        alias /var/www/asset-rmg/frontend/dist;
        index index.html;
        try_files $uri $uri/ /asset_rmg/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {{
            expires 1y;
            add_header Cache-Control "public, immutable";
        }}
    """
    
    return location_line + block_content + "\n    " + next_location

# Replace
new_content = re.sub(pattern, fix_frontend, content, flags=re.DOTALL)

# Ghi lại file
with open(config_file, 'w') as f:
    f.write(new_content)

print("✅ Đã fix frontend config")
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
    sudo grep -A 15 "location /asset_rmg {" "$NGINX_CONFIG" | grep -v "location /asset_rmg/api" | head -20
    
    echo ""
    read -p "Bạn có muốn reload Nginx không? (y/n): " reload
    
    if [ "$reload" = "y" ] || [ "$reload" = "Y" ]; then
        sudo systemctl reload nginx
        echo "✅ Nginx đã reload"
        
        echo ""
        echo "🧪 Test frontend sau khi fix:"
        sleep 1
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
            echo "   ✅ Frontend đang phản hồi!"
        elif [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
            echo "   ⚠️  Frontend vẫn redirect (HTTP $FRONTEND_RESPONSE)"
        else
            echo "   ⚠️  Response: HTTP $FRONTEND_RESPONSE"
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
