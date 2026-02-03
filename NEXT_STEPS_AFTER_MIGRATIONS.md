# ✅ Tiếp tục Setup sau khi Migrations thành công

## ✅ Đã hoàn thành
- ✅ Migrations đã được apply thành công
- ✅ Database schema is up to date

---

## 🔄 Bước tiếp theo

### Bước 1: Generate Prisma Client

```bash
cd /var/www/asset-rmg/backend

# Generate Prisma client
npx prisma generate
```

### Bước 2: Seed Data (Tùy chọn - Tạo dữ liệu mẫu)

```bash
# Seed categories, departments, và admin user
npx prisma db seed
```

**Sau khi seed, bạn sẽ có:**
- **Admin user**: `Mã nhân viên: IT`, `Password: Hainguyen261097`
- **Categories**: Laptop, Phụ kiện IT, Thiết bị Kỹ thuật
- **Departments**: Phòng Công nghệ, Phòng Hành chính, Phòng Kế toán, Kho

### Bước 3: Build Backend

```bash
cd /var/www/asset-rmg/backend

# Build backend
npm run build

# Kiểm tra build thành công
ls -la dist/
# Phải có file: main.js
```

### Bước 4: Setup Frontend

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt dependencies
npm install

# Build với API URL đúng
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
ls -la dist/
# Phải có: index.html, assets/, ...
```

### Bước 5: Start Backend với PM2

```bash
cd /var/www/asset-rmg

# Start backend
pm2 start ecosystem.config.js

# Hoặc start thủ công
cd backend
pm2 start dist/main.js --name asset-rmg-api --update-env

# Lưu PM2 config
pm2 save

# Kiểm tra status
pm2 status
pm2 logs asset-rmg-api
```

### Bước 6: Test Backend API

```bash
# Test API local
curl http://localhost:4001/health

# Test API qua Nginx (sau khi cấu hình)
curl http://27.71.16.15/asset_rmg/api/health
```

### Bước 7: Cấu hình Nginx

```bash
# Backup file config
cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup

# Mở file để chỉnh sửa
nano /etc/nginx/sites-available/it-request-tracking
```

**Thêm vào cuối file, trước dấu `}` cuối cùng:**

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
```

**Test và reload:**
```bash
# Test config
nginx -t

# Nếu OK, reload
systemctl reload nginx
```

### Bước 8: Kiểm tra hoàn chỉnh

#### 8.1. Kiểm tra Backend

```bash
# PM2 status
pm2 status

# Backend logs
pm2 logs asset-rmg-api --lines 20

# Test API
curl http://localhost:4001/health
curl http://27.71.16.15/asset_rmg/api/health
```

#### 8.2. Kiểm tra Frontend

Mở browser và truy cập: **http://27.71.16.15/asset_rmg**

**Kiểm tra:**
- ✅ Trang login hiển thị
- ✅ Logo RMG hiển thị
- ✅ Không có lỗi trong browser console (F12)

#### 8.3. Test đăng nhập

- **Mã nhân viên**: `IT`
- **Password**: `Hainguyen261097`

#### 8.4. Kiểm tra Database

```bash
# Vào PostgreSQL
sudo -u postgres psql -d asset_rmg_db

# Kiểm tra tables
\dt

# Kiểm tra dữ liệu seed
SELECT * FROM "AssetCategory";
SELECT * FROM "users" WHERE "employees_code" = 'IT';
SELECT * FROM "Department";

# Thoát
\q
```

---

## 📝 Checklist hoàn thành

- [x] Migrations đã được apply
- [ ] Prisma client đã được generate
- [ ] Seed data đã chạy (nếu cần)
- [ ] Backend đã build thành công
- [ ] Frontend đã build với đúng API URL
- [ ] Backend đã start với PM2
- [ ] Nginx đã được cấu hình
- [ ] Backend API test OK
- [ ] Frontend load được trên browser
- [ ] Đăng nhập thành công

---

## 🎉 Hoàn thành!

Nếu tất cả các bước trên đã hoàn thành, ứng dụng của bạn đã sẵn sàng tại:

**🌐 URL**: http://27.71.16.15/asset_rmg

**📱 API**: http://27.71.16.15/asset_rmg/api

---

## 🐛 Troubleshooting

### Backend không start

```bash
pm2 logs asset-rmg-api --lines 50
pm2 restart asset-rmg-api
```

### Frontend không load

```bash
# Kiểm tra build
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx
nginx -t
tail -f /var/log/nginx/it-request-error.log
```

### API trả về 404

```bash
# Kiểm tra PM2
pm2 status

# Kiểm tra backend đang chạy trên port 4001
netstat -tulpn | grep 4001

# Kiểm tra Nginx config
grep -A 10 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```
