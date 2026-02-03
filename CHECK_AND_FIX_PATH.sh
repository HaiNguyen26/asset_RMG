#!/bin/bash
# Script kiểm tra và fix path issues (asset-rmq vs asset-rmg)

echo "🔍 Kiểm tra và Fix Path Issues"
echo "==============================="

# Kiểm tra thư mục hiện tại
CURRENT_DIR=$(pwd)
echo ""
echo "📁 Thư mục hiện tại: $CURRENT_DIR"

# Kiểm tra có phải asset-rmq không
if echo "$CURRENT_DIR" | grep -q "asset-rmq"; then
    echo "⚠️  PHÁT HIỆN TYPO: Thư mục hiện tại có 'asset-rmq' thay vì 'asset-rmg'"
    echo ""
    echo "Có 2 khả năng:"
    echo "  1. Thư mục trên server có tên sai: asset-rmq"
    echo "  2. Bạn đang ở thư mục sai"
    echo ""
    read -p "Bạn có muốn kiểm tra thư mục đúng không? (y/n): " check_dir
    
    if [ "$check_dir" = "y" ] || [ "$check_dir" = "Y" ]; then
        # Tìm thư mục đúng
        if [ -d "/var/www/asset-rmg" ]; then
            echo "✅ Tìm thấy thư mục đúng: /var/www/asset-rmg"
            echo "   Chuyển sang thư mục đúng..."
            cd /var/www/asset-rmg
        else
            echo "❌ Không tìm thấy /var/www/asset-rmg"
            echo "   Kiểm tra các thư mục có sẵn:"
            ls -la /var/www/ | grep asset
        fi
    fi
fi

# Kiểm tra thư mục đúng
PROJECT_PATH="/var/www/asset-rmg"
if [ ! -d "$PROJECT_PATH" ]; then
    echo ""
    echo "❌ Thư mục $PROJECT_PATH không tồn tại!"
    echo ""
    echo "Các thư mục có sẵn trong /var/www/:"
    ls -la /var/www/ | grep -E "asset|^d"
    echo ""
    read -p "Nhập đường dẫn đúng đến project (hoặc Enter để bỏ qua): " CUSTOM_PATH
    
    if [ -n "$CUSTOM_PATH" ] && [ -d "$CUSTOM_PATH" ]; then
        PROJECT_PATH="$CUSTOM_PATH"
        echo "✅ Sử dụng: $PROJECT_PATH"
    else
        echo "❌ Không tìm thấy thư mục project"
        exit 1
    fi
fi

cd "$PROJECT_PATH"
echo ""
echo "✅ Đang ở thư mục đúng: $(pwd)"

# Kiểm tra Nginx config có typo không
echo ""
echo "🌐 Kiểm tra Nginx config..."
NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

if [ -f "$NGINX_CONFIG" ]; then
    # Kiểm tra có asset_rmq không
    if sudo grep -q "asset_rmq\|asset-rmq" "$NGINX_CONFIG"; then
        echo "⚠️  PHÁT HIỆN TYPO trong Nginx config: asset_rmq"
        echo ""
        echo "Các dòng có typo:"
        sudo grep -n "asset_rmq\|asset-rmq" "$NGINX_CONFIG"
        echo ""
        read -p "Bạn có muốn fix typo trong Nginx config không? (y/n): " fix_nginx
        
        if [ "$fix_nginx" = "y" ] || [ "$fix_nginx" = "Y" ]; then
            # Backup
            sudo cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Fix typo
            sudo sed -i 's/asset_rmq/asset_rmg/g' "$NGINX_CONFIG"
            sudo sed -i 's/asset-rmq/asset-rmg/g' "$NGINX_CONFIG"
            
            echo "✅ Đã fix typo trong Nginx config"
            
            # Test và reload
            if sudo nginx -t; then
                sudo systemctl reload nginx
                echo "✅ Nginx đã reload"
            else
                echo "❌ Nginx config không hợp lệ sau khi fix"
                echo "   Khôi phục từ backup..."
                sudo cp "${NGINX_CONFIG}.backup."* "$NGINX_CONFIG" 2>/dev/null || true
            fi
        fi
    else
        echo "✅ Nginx config không có typo"
    fi
    
    # Kiểm tra config đúng
    if sudo grep -q "location /asset_rmg" "$NGINX_CONFIG"; then
        echo "✅ Nginx config có location /asset_rmg"
    else
        echo "⚠️  Nginx config chưa có location /asset_rmg"
        echo "   Chạy: sudo ./add-nginx-config.sh"
    fi
else
    echo "⚠️  Không tìm thấy Nginx config: $NGINX_CONFIG"
fi

# Kiểm tra PM2 config
echo ""
echo "⚙️  Kiểm tra PM2 config..."
if [ -f "ecosystem.config.js" ]; then
    if grep -q "asset-rmq" ecosystem.config.js; then
        echo "⚠️  PHÁT HIỆN TYPO trong ecosystem.config.js: asset-rmq"
        read -p "Bạn có muốn fix không? (y/n): " fix_pm2
        
        if [ "$fix_pm2" = "y" ] || [ "$fix_pm2" = "Y" ]; then
            sed -i 's/asset-rmq/asset-rmg/g' ecosystem.config.js
            echo "✅ Đã fix typo trong ecosystem.config.js"
        fi
    else
        echo "✅ PM2 config không có typo"
    fi
else
    echo "⚠️  Không tìm thấy ecosystem.config.js"
fi

# Kiểm tra frontend build config
echo ""
echo "🎨 Kiểm tra Frontend config..."
if [ -f "frontend/vite.config.ts" ]; then
    if grep -q "asset_rmq\|asset-rmq" frontend/vite.config.ts; then
        echo "⚠️  PHÁT HIỆN TYPO trong vite.config.ts"
        read -p "Bạn có muốn fix không? (y/n): " fix_vite
        
        if [ "$fix_vite" = "y" ] || [ "$fix_vite" = "Y" ]; then
            sed -i 's/asset_rmq/asset_rmg/g' frontend/vite.config.ts
            sed -i 's/asset-rmq/asset-rmg/g' frontend/vite.config.ts
            echo "✅ Đã fix typo trong vite.config.ts"
        fi
    else
        echo "✅ Frontend config không có typo"
    fi
fi

# Tóm tắt
echo ""
echo "=========================================="
echo "📋 Tóm tắt:"
echo "=========================================="
echo "Thư mục project: $(pwd)"
echo ""
echo "Kiểm tra URLs:"
echo "  - Frontend: http://27.71.16.15/asset_rmg"
echo "  - API: http://27.71.16.15/asset_rmg/api"
echo "  - Logo: http://27.71.16.15/asset_rmg/RMG-logo.jpg"
echo ""
echo "Nếu vẫn có vấn đề, kiểm tra:"
echo "  1. Thư mục trên server có tên đúng không: /var/www/asset-rmg"
echo "  2. Nginx config có đúng không: location /asset_rmg"
echo "  3. Frontend build có base path đúng không: /asset_rmg/"
