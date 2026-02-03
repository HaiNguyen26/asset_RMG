# 🔧 Quick Fix Nginx Routing - Step by Step

## Vấn đề
`http://27.71.16.15/asset_rmg` đang trỏ vào it-request-tracking thay vì Asset RMG.

## Giải pháp

### Bước 1: Xử lý Git conflict (nếu cần)

```bash
cd /var/www/asset-rmg

# Stash local changes
git stash push -m "Stash before pull"

# Pull code mới
git pull origin main
```

**Lưu ý:** Nếu không cần giữ thay đổi trong `CHECK_APP_STATUS.sh`:
```bash
git checkout -- CHECK_APP_STATUS.sh
git pull origin main
```

---

### Bước 2: Kiểm tra Nginx config hiện tại

```bash
# Xem các location blocks
sudo grep -n "location" /etc/nginx/sites-available/it-request-tracking
```

**Quan trọng:** Ghi nhớ số dòng của:
- `location /asset_rmg` (nếu có)
- `location /` (location root)

---

### Bước 3: Kiểm tra config Asset RMG đã có chưa

```bash
# Kiểm tra config Asset RMG
sudo grep -A 5 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```

**Nếu không có output** → Cần thêm config mới  
**Nếu có output** → Kiểm tra thứ tự location blocks

---

### Bước 4: Sửa Nginx config

#### Option A: Dùng script tự động (sau khi pull code)

```bash
cd /var/www/asset-rmg

# Cho phép script chạy
chmod +x FIX_NGINX_ROUTING.sh

# Chạy script
sudo ./FIX_NGINX_ROUTING.sh
```

#### Option B: Sửa thủ công

```bash
# Backup file config
sudo cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup.$(date +%Y%m%d_%H%M%S)

# Mở file config
sudo nano /etc/nginx/sites-available/it-request-tracking
```

**Thêm config này vào TRƯỚC `location /` block:**

```nginx
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
        
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Asset RMG - Frontend
    location /asset_rmg {
        alias /var/www/asset-rmg/frontend/dist;
        index index.html;
        try_files $uri $uri/ /asset_rmg/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
```

**Lưu file:** `Ctrl+X`, `Y`, `Enter`

---

### Bước 5: Test và reload Nginx

```bash
# Test config
sudo nginx -t

# Nếu test OK, reload
sudo systemctl reload nginx

# Kiểm tra status
sudo systemctl status nginx
```

---

### Bước 6: Kiểm tra routing

```bash
# Test API
curl http://localhost/asset_rmg/api/departments

# Test frontend
curl -I http://localhost/asset_rmg
```

**Hoặc từ browser:**
- `http://27.71.16.15/asset_rmg` → Phải hiển thị Asset RMG frontend
- `http://27.71.16.15/asset_rmg/api/departments` → Phải trả về JSON data

---

## ⚠️ Lưu ý quan trọng

1. **Thứ tự location blocks:**
   - `location /asset_rmg` **PHẢI** đứng trước `location /`
   - Nếu `location /` đứng trước, Nginx sẽ match `/` trước và `/asset_rmg` sẽ không được xử lý

2. **Kiểm tra frontend build:**
   ```bash
   ls -la /var/www/asset-rmg/frontend/dist/index.html
   ```
   File này phải tồn tại, nếu không cần build lại:
   ```bash
   cd /var/www/asset-rmg/frontend
   npm run build
   ```

3. **Kiểm tra backend đang chạy:**
   ```bash
   pm2 status
   pm2 logs asset-rmg-api --lines 20
   ```

---

## 🔍 Troubleshooting

### Nếu vẫn trỏ sai:

1. **Kiểm tra thứ tự location blocks:**
   ```bash
   sudo grep -n "location" /etc/nginx/sites-available/it-request-tracking
   ```
   Đảm bảo số dòng của `location /asset_rmg` < số dòng của `location /`

2. **Kiểm tra Nginx đã reload chưa:**
   ```bash
   sudo systemctl reload nginx
   sudo systemctl status nginx
   ```

3. **Clear browser cache:**
   - Hard refresh: `Ctrl+Shift+R` (Windows) hoặc `Cmd+Shift+R` (Mac)
   - Hoặc test bằng `curl` để tránh cache

4. **Kiểm tra log Nginx:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   sudo tail -f /var/log/nginx/access.log
   ```
