# 🔧 Hướng Dẫn Thêm Nginx Config Cho Asset RMG

## ⚠️ Tình Trạng Hiện Tại

File Nginx config hiện tại: `/etc/nginx/sites-available/it-request-tracking`

Config Asset RMG **chưa được thêm** vào file này.

## 📝 Các Bước Thêm Config

### Bước 1: Backup File Config Hiện Tại

```bash
# Backup để phòng trường hợp cần rollback
sudo cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup.$(date +%Y%m%d_%H%M%S)

# Kiểm tra backup đã tạo
ls -la /etc/nginx/sites-available/it-request-tracking.backup*
```

### Bước 2: Xem Cấu Trúc File Config Hiện Tại

```bash
# Xem toàn bộ file để hiểu cấu trúc
sudo cat /etc/nginx/sites-available/it-request-tracking

# Hoặc xem với line numbers để dễ chỉnh sửa
sudo cat -n /etc/nginx/sites-available/it-request-tracking | tail -20
```

**Tìm dòng cuối cùng** có dấu `}` đóng block `server { ... }`

### Bước 3: Mở File Để Chỉnh Sửa

```bash
sudo nano /etc/nginx/sites-available/it-request-tracking
```

### Bước 4: Thêm Config Asset RMG

**Tìm đến cuối file**, trước dấu `}` cuối cùng của block `server { ... }`, thêm các dòng sau:

```nginx
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
```

**Lưu ý quan trọng:**
- Thêm **trước** dấu `}` cuối cùng của block `server { ... }`
- Giữ nguyên tất cả config của IT Request Tracking
- Đảm bảo indentation đúng (thụt vào 4 spaces)

### Bước 5: Lưu File

Trong nano:
1. Nhấn `Ctrl + X` để thoát
2. Nhấn `Y` để xác nhận lưu
3. Nhấn `Enter` để xác nhận tên file

### Bước 6: Test Cấu Hình Nginx

```bash
# Test cấu hình (QUAN TRỌNG!)
sudo nginx -t
```

**Kết quả mong đợi:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Nếu có lỗi**, kiểm tra lại:
- Dấu `;` ở cuối mỗi dòng
- Dấu `}` đóng các block đúng
- Không có dấu ngoặc thừa

### Bước 7: Reload Nginx

```bash
# Chỉ reload nếu test thành công
sudo systemctl reload nginx

# Kiểm tra status
sudo systemctl status nginx
```

### Bước 8: Kiểm Tra Config Đã Được Thêm

```bash
# Kiểm tra config Asset RMG đã có
sudo grep -A 5 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```

**Kết quả mong đợi:** Phải thấy 2 location blocks:
- `location /asset_rmg/api`
- `location /asset_rmg`

## 🔍 Kiểm Tra Sau Khi Thêm

### Test Backend API

```bash
# Test từ server
curl http://localhost:4001/api/health || echo "Backend chưa chạy"

# Test qua Nginx
curl http://localhost/asset_rmg/api/health || echo "Nginx config chưa đúng"
```

### Test Frontend

```bash
# Kiểm tra file frontend đã build chưa
ls -la /var/www/asset-rmg/frontend/dist/index.html

# Test truy cập qua browser
# http://27.71.16.15/asset_rmg
```

## 🚨 Troubleshooting

### Nếu `nginx -t` báo lỗi:

```bash
# Xem lỗi chi tiết
sudo nginx -t 2>&1 | grep -A 5 error

# Kiểm tra syntax
sudo nginx -T | grep -A 10 "location /asset_rmg"
```

### Nếu không truy cập được:

```bash
# Kiểm tra Nginx logs
sudo tail -f /var/log/nginx/error.log

# Kiểm tra PM2 đang chạy
pm2 status | grep asset-rmg-api

# Kiểm tra port 4001
sudo netstat -tlnp | grep 4001
```

### Rollback Nếu Cần:

```bash
# Khôi phục từ backup
sudo cp /etc/nginx/sites-available/it-request-tracking.backup.* /etc/nginx/sites-available/it-request-tracking

# Test và reload
sudo nginx -t
sudo systemctl reload nginx
```

## ✅ Checklist

- [ ] Backup file config cũ
- [ ] Thêm config Asset RMG vào file `it-request-tracking`
- [ ] Test cấu hình: `sudo nginx -t` ✅
- [ ] Reload Nginx: `sudo systemctl reload nginx`
- [ ] Kiểm tra config: `sudo grep "location /asset_rmg" ...`
- [ ] Test backend: `curl http://localhost/asset_rmg/api/...`
- [ ] Test frontend: Truy cập `http://27.71.16.15/asset_rmg`

## 📝 Lưu Ý

- **KHÔNG** xóa hoặc sửa config của IT Request Tracking
- **CHỈ** thêm config mới vào cuối file
- Luôn test trước khi reload: `sudo nginx -t`
- Giữ backup file để có thể rollback nếu cần
