#!/bin/bash

# Script để thêm cấu hình Asset RMG vào file Nginx hiện có
# Chạy script này trên server sau khi đã setup project

set -e

echo "🔧 Adding Asset RMG config to existing Nginx configuration..."

# Find active Nginx config - IT Request Tracking
NGINX_CONFIG=""
if [ -f "/etc/nginx/sites-available/it-request-tracking" ]; then
    NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"
elif [ -f "/etc/nginx/sites-enabled/it-request-tracking" ]; then
    NGINX_CONFIG="/etc/nginx/sites-enabled/it-request-tracking"
else
    echo "❌ Could not find it-request-tracking config file!"
    echo "Please check: ls -la /etc/nginx/sites-available/"
    exit 1
fi

if [ -z "$NGINX_CONFIG" ] || [ ! -f "$NGINX_CONFIG" ]; then
    echo "❌ Could not find Nginx config file!"
    echo "Please specify the config file path manually."
    exit 1
fi

echo "📝 Found Nginx config: $NGINX_CONFIG"

# Backup original config
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Check if config already exists
if grep -q "location /asset_rmg" "$NGINX_CONFIG"; then
    echo "⚠️  Asset RMG config already exists in $NGINX_CONFIG"
    echo "Skipping..."
    exit 0
fi

# Create temp file with new config
TEMP_FILE=$(mktemp)

# Read original config and add new location blocks before the last closing brace
awk '
    /^[[:space:]]*}[[:space:]]*$/ && !done {
        # Add Asset RMG config before the last closing brace
        print "    # Asset RMG - Backend API"
        print "    location /asset_rmg/api {"
        print "        proxy_pass http://localhost:4001;"
        print "        proxy_http_version 1.1;"
        print "        proxy_set_header Upgrade $http_upgrade;"
        print "        proxy_set_header Connection '\''upgrade'\'';"
        print "        proxy_set_header Host $host;"
        print "        proxy_set_header X-Real-IP $remote_addr;"
        print "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
        print "        proxy_set_header X-Forwarded-Proto $scheme;"
        print "        proxy_cache_bypass $http_upgrade;"
        print "    }"
        print ""
        print "    # Asset RMG - Frontend"
        print "    location /asset_rmg {"
        print "        alias /var/www/asset-rmg/frontend/dist;"
        print "        index index.html;"
        print "        try_files $uri $uri/ /asset_rmg/index.html;"
        print ""
        print "        location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {"
        print "            expires 1y;"
        print "            add_header Cache-Control \"public, immutable\";"
        print "        }"
        print "    }"
        print ""
        done = 1
    }
    { print }
' "$NGINX_CONFIG" > "$TEMP_FILE"

# Replace original with new config
mv "$TEMP_FILE" "$NGINX_CONFIG"

echo "✅ Config added to $NGINX_CONFIG"

# Test Nginx config
echo "🧪 Testing Nginx configuration..."
if nginx -t; then
    echo "✅ Nginx config test passed!"
    echo "🔄 Reloading Nginx..."
    systemctl reload nginx
    echo "✅ Nginx reloaded successfully!"
else
    echo "❌ Nginx config test failed!"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$NGINX_CONFIG"
    echo "Backup restored. Please check the config manually."
    exit 1
fi

echo ""
echo "🎉 Asset RMG Nginx configuration added successfully!"
echo "🌐 Access your app at: http://27.71.16.15/asset_rmg"
