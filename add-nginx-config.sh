#!/bin/bash
# Script tự động thêm Nginx config cho Asset RMG vào file it-request-tracking

set -e  # Dừng nếu có lỗi

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
ASSET_RMG_CONFIG="/var/www/asset-rmg/nginx-asset-rmg.conf"

echo "🔧 Script tự động thêm Nginx config cho Asset RMG"
echo "=================================================="

# Kiểm tra file Nginx config tồn tại
if [ ! -f "$NGINX_CONFIG" ]; then
    echo "❌ Không tìm thấy file: $NGINX_CONFIG"
    echo "   Vui lòng kiểm tra đường dẫn file Nginx config"
    exit 1
fi

# Kiểm tra config Asset RMG đã có chưa
if grep -q "location /asset_rmg" "$NGINX_CONFIG"; then
    echo "⚠️  Config Asset RMG đã tồn tại trong file Nginx"
    echo "   Bạn có muốn ghi đè không? (y/n)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "❌ Hủy bỏ. Không thay đổi gì."
        exit 0
    fi
    echo "🔄 Xóa config cũ..."
    # Xóa config cũ (từ "location /asset_rmg" đến dấu } cuối cùng của block đó)
    sed -i '/# Asset RMG/,/^[[:space:]]*}$/d' "$NGINX_CONFIG"
fi

# Backup file config
echo "📦 Backup file config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Kiểm tra file config Asset RMG trong repo
if [ -f "$ASSET_RMG_CONFIG" ]; then
    echo "📄 Sử dụng config từ repo: $ASSET_RMG_CONFIG"
    CONFIG_CONTENT=$(cat "$ASSET_RMG_CONFIG")
else
    echo "📝 Tạo config từ template..."
    # Tạo config từ template
    CONFIG_CONTENT=$(cat << 'EOF'
    # Asset RMG - Backend API
    location /asset_rmg/api {
        proxy_pass http://localhost:4001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers if needed
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Asset RMG - Frontend
    location /asset_rmg {
        alias /var/www/asset-rmg/frontend/dist;
        index index.html;
        try_files $uri $uri/ /asset_rmg/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
EOF
)
fi

# Tìm dòng cuối cùng có dấu } đóng block server
LAST_LINE=$(grep -n "^}" "$NGINX_CONFIG" | tail -1 | cut -d: -f1)

if [ -z "$LAST_LINE" ]; then
    echo "❌ Không tìm thấy dấu } đóng block server"
    echo "   Vui lòng kiểm tra cấu trúc file Nginx config"
    exit 1
fi

echo "📍 Tìm thấy dòng đóng block server tại dòng: $LAST_LINE"

# Thêm config vào trước dòng cuối cùng
echo "➕ Thêm config Asset RMG vào file..."
sudo sed -i "${LAST_LINE}i\\$CONFIG_CONTENT" "$NGINX_CONFIG"

# Thêm indentation (4 spaces) cho mỗi dòng config
sudo sed -i "${LAST_LINE}i\\    # Asset RMG - Backend API" "$NGINX_CONFIG"
sudo sed -i "${LAST_LINE}i\\    location /asset_rmg/api {" "$NGINX_CONFIG"
sudo sed -i "${LAST_LINE}i\\        proxy_pass http://localhost:4001;" "$NGINX_CONFIG"
# ... (cách này phức tạp, dùng cách khác)

# Cách đơn giản hơn: dùng Python hoặc awk để insert
echo "➕ Thêm config vào file Nginx..."

# Tạo file temp với config đã format đúng
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << 'EOF'
    # ============================================
    # Asset RMG - Backend API
    # ============================================
    location /asset_rmg/api {
        proxy_pass http://localhost:4001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers if needed
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # ============================================
    # Asset RMG - Frontend
    # ============================================
    location /asset_rmg {
        alias /var/www/asset-rmg/frontend/dist;
        index index.html;
        try_files $uri $uri/ /asset_rmg/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
EOF

# Insert config vào trước dòng cuối cùng
sudo python3 << PYTHON_SCRIPT
import sys

config_file = "$NGINX_CONFIG"
temp_config = "$TEMP_CONFIG"

# Đọc file config hiện tại
with open(config_file, 'r') as f:
    lines = f.readlines()

# Đọc config cần thêm
with open(temp_config, 'r') as f:
    new_config = f.read()

# Tìm dòng cuối cùng có dấu } đóng block server
last_brace_line = None
for i in range(len(lines) - 1, -1, -1):
    if lines[i].strip() == '}':
        last_brace_line = i
        break

if last_brace_line is None:
    print("❌ Không tìm thấy dấu } đóng block server")
    sys.exit(1)

# Insert config vào trước dòng cuối cùng
lines.insert(last_brace_line, new_config)

# Ghi lại file
with open(config_file, 'w') as f:
    f.writelines(lines)

print(f"✅ Đã thêm config vào dòng {last_brace_line}")
PYTHON_SCRIPT

# Xóa file temp
rm -f "$TEMP_CONFIG"

# Test cấu hình Nginx
echo ""
echo "🧪 Test cấu hình Nginx..."
if sudo nginx -t; then
    echo "✅ Cấu hình Nginx hợp lệ!"
    
    echo ""
    echo "🔄 Reload Nginx..."
    sudo systemctl reload nginx
    
    echo ""
    echo "✅ Hoàn thành!"
    echo ""
    echo "📋 Kiểm tra config đã được thêm:"
    sudo grep -A 3 "location /asset_rmg" "$NGINX_CONFIG" | head -10
    
    echo ""
    echo "🌐 Ứng dụng có thể truy cập tại:"
    echo "   - Frontend: http://27.71.16.15/asset_rmg"
    echo "   - Backend API: http://27.71.16.15/asset_rmg/api"
else
    echo "❌ Cấu hình Nginx không hợp lệ!"
    echo "🔄 Khôi phục từ backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    echo "✅ Đã khôi phục từ backup"
    exit 1
fi
