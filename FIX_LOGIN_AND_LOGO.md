# 🔧 Fix Lỗi Login và Logo

## Vấn đề

1. **API Login 404**: `Cannot POST /asset_rmg/api/auth/login`
2. **Logo bị mất**: Logo không hiển thị

## Nguyên nhân

### 1. API Login 404

Có thể do:
- Nginx config chưa proxy đúng `/asset_rmg/api` đến backend
- Backend chưa chạy hoặc không lắng nghe trên port 4001
- VITE_API_URL chưa được set đúng khi build frontend

### 2. Logo bị mất

- Logo path `/RMG-logo.jpg` không đúng với base path `/asset_rmg/`
- Cần dùng `${import.meta.env.BASE_URL}RMG-logo.jpg` để tự động thêm base path

## Giải pháp

### Bước 1: Fix Logo Path (Đã fix trong code)

Logo đã được fix để dùng `import.meta.env.BASE_URL` tự động.

### Bước 2: Kiểm tra và Fix API

#### 2.1. Kiểm tra Backend đang chạy

```bash
# Kiểm tra PM2
pm2 status

# Xem logs backend
pm2 logs asset-rmg-api --lines 30

# Test API trực tiếp (không qua Nginx)
curl -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"IT","password":"test"}'
```

**Nếu backend không chạy:**
```bash
cd /var/www/asset-rmg
pm2 restart asset-rmg-api
# Hoặc
pm2 start ecosystem.config.js
```

#### 2.2. Kiểm tra Nginx Config

```bash
# Kiểm tra config đã có chưa
sudo grep -A 10 "location /asset_rmg/api" /etc/nginx/sites-available/it-request-tracking

# Nếu chưa có, thêm config (xem add-nginx-config.sh)
```

**Config cần có:**
```nginx
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
```

#### 2.3. Kiểm tra Frontend Build

```bash
# Kiểm tra VITE_API_URL khi build
cd /var/www/asset-rmg/frontend

# Rebuild với đúng API URL
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra file build có đúng không
grep -r "VITE_API_URL\|27.71.16.15" dist/ | head -5
```

#### 2.4. Test API qua Nginx

```bash
# Test API endpoint
curl -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"IT","password":"test"}'

# Hoặc test từ browser console:
# fetch('http://27.71.16.15/asset_rmg/api/auth/login', {
#   method: 'POST',
#   headers: {'Content-Type': 'application/json'},
#   body: JSON.stringify({employeesCode: 'IT', password: 'test'})
# })
```

### Bước 3: Rebuild Frontend

```bash
cd /var/www/asset-rmg/frontend

# Đảm bảo VITE_API_URL đúng
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"

# Build lại
npm run build

# Kiểm tra logo file có tồn tại không
ls -la dist/RMG-logo.jpg
ls -la public/RMG-logo.jpg
```

**Lưu ý:** File logo phải ở trong `public/` folder để được copy vào `dist/` khi build.

### Bước 4: Reload Nginx

```bash
# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

## Script Tự Động Fix

```bash
cd /var/www/asset-rmg

# Pull code mới (có fix logo)
git stash push -m "Stash before pull"
git pull origin main

# Rebuild frontend với đúng API URL
cd frontend
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra backend
cd ..
pm2 restart asset-rmg-api

# Kiểm tra Nginx config
sudo grep -A 5 "location /asset_rmg/api" /etc/nginx/sites-available/it-request-tracking

# Nếu chưa có, thêm config
sudo ./add-nginx-config.sh

# Reload Nginx
sudo systemctl reload nginx
```

## Kiểm Tra Sau Khi Fix

### 1. Test API Login

```bash
curl -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"IT","password":"your_password"}'
```

**Kết quả mong đợi:** JSON response với `access_token` và `user`

### 2. Test Logo

- Truy cập: http://27.71.16.15/asset_rmg
- Kiểm tra logo hiển thị trên trang login và sidebar

### 3. Test từ Browser Console

```javascript
// Test API
fetch('http://27.71.16.15/asset_rmg/api/auth/login', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({employeesCode: 'IT', password: 'your_password'})
})
.then(r => r.json())
.then(console.log)
.catch(console.error)

// Test Logo
const img = new Image()
img.onload = () => console.log('Logo loaded:', img.src)
img.onerror = () => console.error('Logo failed:', img.src)
img.src = 'http://27.71.16.15/asset_rmg/RMG-logo.jpg'
```

## Troubleshooting

### Nếu API vẫn 404:

1. **Kiểm tra backend logs:**
   ```bash
   pm2 logs asset-rmg-api --err
   ```

2. **Kiểm tra backend route:**
   ```bash
   curl http://localhost:4001/api/auth/login
   # Phải trả về method not allowed (405) chứ không phải 404
   ```

3. **Kiểm tra Nginx proxy:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   # Thử login từ browser và xem log
   ```

### Nếu Logo vẫn mất:

1. **Kiểm tra file logo:**
   ```bash
   ls -la /var/www/asset-rmg/frontend/public/RMG-logo.jpg
   ls -la /var/www/asset-rmg/frontend/dist/RMG-logo.jpg
   ```

2. **Kiểm tra base path trong HTML:**
   ```bash
   grep -i "base\|asset_rmg" /var/www/asset-rmg/frontend/dist/index.html
   ```

3. **Kiểm tra Nginx serve static files:**
   ```bash
   curl -I http://localhost/asset_rmg/RMG-logo.jpg
   ```

## Kết quả mong đợi

✅ API Login hoạt động: `POST /asset_rmg/api/auth/login` trả về token  
✅ Logo hiển thị trên trang login và sidebar  
✅ Tất cả static assets (JS, CSS, images) load đúng
