#!/bin/bash
# Script tự động thêm config Asset RMG vào Nginx config file

set -e

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Thêm config Asset RMG vào Nginx..."
echo "======================================"

# Kiểm tra file config tồn tại
if [ ! -f "$NGINX_CONFIG" ]; then
    echo "❌ File Nginx config không tồn tại: $NGINX_CONFIG"
    exit 1
fi

# Kiểm tra config đã có chưa
if grep -q "location /asset_rmg" "$NGINX_CONFIG"; then
    echo "⚠️  Config Asset RMG đã có trong file!"
    echo ""
    echo "📋 Config hiện tại:"
    grep -A 10 "location /asset_rmg" "$NGINX_CONFIG" | head -15
    echo ""
    read -p "Bạn có muốn thêm lại không? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Đã hủy"
        exit 0
    fi
fi

# Backup file
echo ""
echo "💾 Backup file config..."
cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Tìm vị trí để thêm config
# Tìm dòng cuối cùng có "location /" (location root)
LOCATION_ROOT_LINE=$(grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$LOCATION_ROOT_LINE" ]; then
    # Nếu không có location /, tìm dòng cuối cùng có dấu } đóng block server
    LAST_BRACE_LINE=$(grep -n "^}" "$NGINX_CONFIG" | tail -1 | cut -d: -f1)
    
    if [ -z "$LAST_BRACE_LINE" ]; then
        echo "❌ Không tìm thấy vị trí để thêm config"
        echo "   Vui lòng thêm thủ công vào cuối file"
        exit 1
    fi
    
    INSERT_LINE=$LAST_BRACE_LINE
    echo "📍 Tìm thấy vị trí: dòng $INSERT_LINE (trước dấu } cuối cùng)"
else
    INSERT_LINE=$LOCATION_ROOT_LINE
    echo "📍 Tìm thấy vị trí: dòng $INSERT_LINE (trước location /)"
fi

# Config cần thêm
ASSET_RMG_CONFIG=$(cat << 'EOF'
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
        
        # CORS headers
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

# Thêm config vào file
echo ""
echo "➕ Đang thêm config vào file..."

# Sử dụng Python để insert config một cách an toàn
python3 << PYTHON_SCRIPT
import sys

config_file = "$NGINX_CONFIG"
insert_line = int("$INSERT_LINE")
new_config = """$ASSET_RMG_CONFIG"""

try:
    # Đọc file
    with open(config_file, 'r') as f:
        lines = f.readlines()
    
    # Insert config vào trước dòng chỉ định
    # Giảm 1 vì Python index từ 0
    lines.insert(insert_line - 1, new_config)
    
    # Ghi lại file
    with open(config_file, 'w') as f:
        f.writelines(lines)
    
    print(f"✅ Đã thêm config vào dòng {insert_line}")
    sys.exit(0)
except Exception as e:
    print(f"❌ Lỗi: {e}")
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -ne 0 ]; then
    echo "❌ Không thể thêm config tự động"
    echo "   Khôi phục từ backup..."
    cp "$BACKUP_FILE" "$NGINX_CONFIG"
    exit 1
fi

# Test Nginx config
echo ""
echo "🧪 Test Nginx config..."
if sudo nginx -t; then
    echo "✅ Nginx config hợp lệ"
    
    # Hiển thị config vừa thêm
    echo ""
    echo "📋 Config vừa thêm:"
    grep -A 15 "location /asset_rmg" "$NGINX_CONFIG" | head -20
    
    # Hỏi có muốn reload không
    echo ""
    read -p "Bạn có muốn reload Nginx ngay không? (y/n): " reload_confirm
    if [ "$reload_confirm" = "y" ] || [ "$reload_confirm" = "Y" ]; then
        echo ""
        echo "🔄 Reloading Nginx..."
        if sudo systemctl reload nginx; then
            echo "✅ Nginx đã được reload"
            echo ""
            echo "🌐 Test ứng dụng:"
            echo "   curl http://localhost/asset_rmg/api/departments"
            echo "   Hoặc truy cập: http://27.71.16.15/asset_rmg"
        else
            echo "❌ Nginx reload failed"
            exit 1
        fi
    else
        echo ""
        echo "⚠️  Chưa reload Nginx"
        echo "   Chạy lệnh sau để reload:"
        echo "   sudo systemctl reload nginx"
    fi
else
    echo "❌ Nginx config không hợp lệ!"
    echo "   Khôi phục từ backup..."
    cp "$BACKUP_FILE" "$NGINX_CONFIG"
    echo "✅ Đã khôi phục từ backup"
    exit 1
fi

echo ""
echo "✅ Hoàn thành!"
