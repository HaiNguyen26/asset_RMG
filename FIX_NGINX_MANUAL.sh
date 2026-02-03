#!/bin/bash
# Script fix Nginx config thủ công - đảm bảo syntax đúng

set -e

NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Fix Nginx Config - Manual Method"
echo "===================================="

# Backup
echo ""
echo "💾 Backup file config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Đã backup: $BACKUP_FILE"

# Kiểm tra config hiện tại
echo ""
echo "📋 Config hiện tại cho /asset_rmg/api (dòng 20-40):"
sudo sed -n '20,40p' "$NGINX_CONFIG"

# Tạo config đúng format
echo ""
echo "🔧 Tạo config đúng format..."

# Tạo file temp với config đúng
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << 'EOF'
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
EOF

# Tìm dòng bắt đầu của location /asset_rmg/api
START_LINE=$(sudo grep -n "location /asset_rmg/api" "$NGINX_CONFIG" | head -1 | cut -d: -f1)

if [ -z "$START_LINE" ]; then
    echo "❌ Không tìm thấy location /asset_rmg/api"
    echo "   Cần thêm config mới"
    
    # Tìm vị trí để thêm (trước location /asset_rmg hoặc location /)
    INSERT_LINE=$(sudo grep -n "^[[:space:]]*location /asset_rmg {" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
    
    if [ -z "$INSERT_LINE" ]; then
        INSERT_LINE=$(sudo grep -n "^[[:space:]]*location /[[:space:]]*{" "$NGINX_CONFIG" | head -1 | cut -d: -f1)
    fi
    
    if [ -z "$INSERT_LINE" ]; then
        echo "❌ Không tìm thấy vị trí để thêm config"
        exit 1
    fi
    
    echo "   Thêm config vào dòng $INSERT_LINE"
    
    # Insert config
    sudo sed -i "${INSERT_LINE}i\\$(cat $TEMP_CONFIG)" "$NGINX_CONFIG"
else
    echo "   Tìm thấy config tại dòng $START_LINE"
    
    # Tìm dòng kết thúc của block (dòng có dấu } đóng)
    END_LINE=$START_LINE
    BRACE_COUNT=0
    FOUND_START=0
    
    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))
        if [ "$LINE_NUM" -ge "$START_LINE" ]; then
            if echo "$line" | grep -q "location /asset_rmg/api"; then
                FOUND_START=1
                BRACE_COUNT=1
            elif [ "$FOUND_START" -eq 1 ]; then
                OPEN_BRACES=$(echo "$line" | grep -o '{' | wc -l)
                CLOSE_BRACES=$(echo "$line" | grep -o '}' | wc -l)
                BRACE_COUNT=$((BRACE_COUNT + OPEN_BRACES - CLOSE_BRACES))
                
                if [ "$BRACE_COUNT" -eq 0 ]; then
                    END_LINE=$LINE_NUM
                    break
                fi
            fi
        fi
    done < <(sudo cat "$NGINX_CONFIG" | nl -ba)
    
    if [ "$END_LINE" -eq "$START_LINE" ]; then
        # Không tìm thấy dòng kết thúc, dùng cách đơn giản hơn
        END_LINE=$((START_LINE + 25))  # Giả định block dài khoảng 25 dòng
    fi
    
    echo "   Thay thế config từ dòng $START_LINE đến $END_LINE"
    
    # Xóa config cũ và thêm config mới
    sudo sed -i "${START_LINE},${END_LINE}d" "$NGINX_CONFIG"
    sudo sed -i "$((START_LINE-1))r $TEMP_CONFIG" "$NGINX_CONFIG"
fi

# Xóa temp file
rm -f "$TEMP_CONFIG"

# Test config
echo ""
echo "🧪 Test Nginx config..."
if sudo nginx -t; then
    echo "✅ Nginx config hợp lệ"
    
    echo ""
    echo "📋 Config sau khi fix (dòng $START_LINE-$((START_LINE+20))):"
    sudo sed -n "${START_LINE},$((START_LINE+20))p" "$NGINX_CONFIG"
    
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
    
    echo ""
    echo "⚠️  Vui lòng fix thủ công:"
    echo "   1. Mở file: sudo nano $NGINX_CONFIG"
    echo "   2. Tìm location /asset_rmg/api"
    echo "   3. Đảm bảo mỗi proxy_set_header chỉ có 2 arguments"
    echo "   4. Xem config mẫu trong file này"
    exit 1
fi

echo ""
echo "✅ Hoàn thành!"
