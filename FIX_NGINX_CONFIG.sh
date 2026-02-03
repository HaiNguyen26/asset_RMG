#!/bin/bash
# Script kiểm tra và fix Nginx config cho Asset RMG

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

echo "🔧 Kiểm tra và fix Nginx config..."
echo "===================================="

# 1. Kiểm tra config hiện tại
echo ""
echo "1️⃣  Kiểm tra Nginx config hiện tại:"
if [ ! -f "$NGINX_CONFIG" ]; then
    echo "❌ File Nginx config không tồn tại: $NGINX_CONFIG"
    echo "   Tìm file config khác..."
    NGINX_CONFIG=$(find /etc/nginx -name "*.conf" -o -name "*it-request*" 2>/dev/null | head -1)
    if [ -z "$NGINX_CONFIG" ]; then
        echo "❌ Không tìm thấy file config!"
        exit 1
    fi
    echo "   Tìm thấy: $NGINX_CONFIG"
fi

# 2. Kiểm tra config Asset RMG đã có chưa
echo ""
echo "2️⃣  Kiểm tra config Asset RMG:"
if grep -q "location /asset_rmg" "$NGINX_CONFIG"; then
    echo "✅ Config Asset RMG đã có trong file"
    echo ""
    echo "📋 Config hiện tại:"
    grep -A 10 "location /asset_rmg" "$NGINX_CONFIG" | head -15
else
    echo "❌ Config Asset RMG CHƯA có trong file!"
    echo ""
    echo "3️⃣  Thêm config Asset RMG..."
    
    # Backup file
    cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Đã backup file config"
    
    # Tìm dòng cuối cùng có dấu } đóng block server
    LAST_BRACE_LINE=$(grep -n "^}" "$NGINX_CONFIG" | tail -1 | cut -d: -f1)
    
    if [ -z "$LAST_BRACE_LINE" ]; then
        echo "❌ Không tìm thấy dấu } đóng block server"
        exit 1
    fi
    
    echo "   Tìm thấy dòng đóng block server tại: $LAST_BRACE_LINE"
    
    # Tạo config Asset RMG
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
    
    # Insert config vào trước dòng cuối cùng
    python3 << PYTHON_SCRIPT
import sys

config_file = "$NGINX_CONFIG"
new_config = """$ASSET_RMG_CONFIG"""

# Đọc file
with open(config_file, 'r') as f:
    lines = f.readlines()

# Tìm dòng cuối cùng có dấu }
last_brace_line = None
for i in range(len(lines) - 1, -1, -1):
    if lines[i].strip() == '}':
        last_brace_line = i
        break

if last_brace_line is None:
    print("❌ Không tìm thấy dấu } đóng block server")
    sys.exit(1)

# Insert config
lines.insert(last_brace_line, new_config)

# Ghi lại file
with open(config_file, 'w') as f:
    f.writelines(lines)

print(f"✅ Đã thêm config vào dòng {last_brace_line}")
PYTHON_SCRIPT
    
    if [ $? -eq 0 ]; then
        echo "✅ Đã thêm config Asset RMG"
    else
        echo "❌ Không thể thêm config tự động"
        echo "   Vui lòng thêm thủ công (xem nginx-asset-rmg.conf)"
        exit 1
    fi
fi

# 4. Test và reload Nginx
echo ""
echo "4️⃣  Test Nginx config:"
if nginx -t; then
    echo "✅ Nginx config hợp lệ"
    
    echo ""
    echo "5️⃣  Reload Nginx..."
    systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ Nginx đã được reload"
    else
        echo "❌ Nginx reload failed"
        exit 1
    fi
else
    echo "❌ Nginx config không hợp lệ!"
    echo "   Khôi phục từ backup..."
    BACKUP_FILE=$(ls -t "${NGINX_CONFIG}".backup.* 2>/dev/null | head -1)
    if [ -n "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$NGINX_CONFIG"
        echo "✅ Đã khôi phục từ backup"
    fi
    exit 1
fi

# 5. Kiểm tra lại
echo ""
echo "6️⃣  Kiểm tra config sau khi reload:"
grep -A 3 "location /asset_rmg" "$NGINX_CONFIG" | head -10

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "🌐 Test:"
echo "   curl http://localhost/asset_rmg/api/departments"
echo "   Hoặc truy cập: http://27.71.16.15/asset_rmg"
