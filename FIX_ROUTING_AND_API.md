# 🔧 Fix Routing và API Issues

## Vấn đề

1. **Redirect sai**: Truy cập `http://27.71.16.15/asset_rmg` → redirect về `http://27.71.16.15/login` (thiếu base path)
2. **API 404**: `Cannot POST /asset_rmg/api/auth/login`

## Nguyên nhân

### 1. React Router thiếu basename

React Router `BrowserRouter` không biết base path `/asset_rmg/` nên:
- Truy cập `/asset_rmg` không match với route `/login`
- Redirect về `/login` (không có base path) → `http://27.71.16.15/login`

**Giải pháp**: Thêm `basename` prop vào `BrowserRouter`

### 2. API 404

- Nginx config chưa proxy đúng `/asset_rmg/api` đến backend
- Hoặc backend chưa chạy

## Giải pháp

### Bước 1: Fix React Router (Đã fix trong code)

Đã thêm `basename={import.meta.env.BASE_URL}` vào `BrowserRouter` để tự động nhận base path từ Vite config.

### Bước 2: Rebuild Frontend

```bash
cd /var/www/asset-rmg/frontend

# Build với đúng API URL và base path
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

### Bước 3: Kiểm tra Nginx Config

```bash
# Kiểm tra config đã có chưa
sudo grep -A 10 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```

**Config cần có:**

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

**Quan trọng**: `location /asset_rmg` phải đứng TRƯỚC `location /` trong file config!

### Bước 4: Kiểm tra Backend

```bash
# Kiểm tra PM2
pm2 status

# Restart nếu cần
pm2 restart asset-rmg-api

# Test backend trực tiếp
curl -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"test","password":"test"}'
```

### Bước 5: Reload Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Script Tự Động Fix

```bash
cd /var/www/asset-rmg

# Pull code mới (có fix basename)
git stash push -m "Stash before pull"
git pull origin main

# Rebuild frontend
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

### 1. Test Routing

- Truy cập: `http://27.71.16.15/asset_rmg`
- **Kết quả mong đợi**: Hiển thị trang login tại `http://27.71.16.15/asset_rmg/login` (KHÔNG redirect về `/login`)

### 2. Test API

```bash
curl -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"IT","password":"your_password"}'
```

**Kết quả mong đợi**: JSON với `access_token` hoặc 401 (nếu sai password)

### 3. Test từ Browser

- Truy cập: `http://27.71.16.15/asset_rmg`
- Thử đăng nhập
- Kiểm tra Network tab trong DevTools:
  - Request URL phải là: `http://27.71.16.15/asset_rmg/api/auth/login`
  - Không được redirect về `/login`

## Troubleshooting

### Nếu vẫn redirect về `/login`:

1. **Kiểm tra build có đúng không:**
   ```bash
   grep -r "basename" /var/www/asset-rmg/frontend/dist/assets/*.js | head -1
   ```

2. **Kiểm tra base path trong HTML:**
   ```bash
   grep -i "base\|asset_rmg" /var/www/asset-rmg/frontend/dist/index.html
   ```

3. **Clear browser cache:**
   - Hard refresh: `Ctrl+Shift+R` (Windows) hoặc `Cmd+Shift+R` (Mac)

### Nếu API vẫn 404:

1. **Kiểm tra Nginx logs:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

2. **Kiểm tra backend logs:**
   ```bash
   pm2 logs asset-rmg-api --lines 30
   ```

3. **Test backend trực tiếp:**
   ```bash
   curl http://localhost:4001/api/auth/login
   # Phải trả về 405 (Method Not Allowed) chứ không phải 404
   ```

4. **Kiểm tra Nginx proxy:**
   ```bash
   curl -v http://localhost/asset_rmg/api/auth/login
   ```

## Kết quả mong đợi

✅ Truy cập `/asset_rmg` → Hiển thị login page tại `/asset_rmg/login`  
✅ API Login hoạt động: `POST /asset_rmg/api/auth/login`  
✅ Không redirect về `/login` (thiếu base path)  
✅ Tất cả routes hoạt động với base path `/asset_rmg/`
