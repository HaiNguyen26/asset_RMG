# 🚀 Hướng Dẫn Chạy Web App Asset RMG

## 📍 Trên Server (27.71.16.15)

### Cách 1: Tự động (Khuyến nghị) ⭐

```bash
cd /var/www/asset-rmg

# Cho phép script chạy
chmod +x START_WEB_APP.sh

# Chạy script tự động
sudo ./START_WEB_APP.sh
```

Script này sẽ tự động:
- ✅ Pull code mới nhất
- ✅ Build backend
- ✅ Build frontend  
- ✅ Setup Nginx config
- ✅ Start PM2
- ✅ Reload Nginx

---

### Cách 2: Thủ công (Từng bước)

#### Bước 1: Pull code mới nhất

```bash
cd /var/www/asset-rmg
git pull origin main
```

#### Bước 2: Build Backend

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra .env file
if [ ! -f .env ]; then
    cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
fi

# Cài đặt dependencies
npm install

# Generate Prisma Client
npx prisma generate

# Chạy migrations
npx prisma migrate deploy

# Build backend
npm run build
```

#### Bước 3: Build Frontend

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt dependencies
npm install

# Build với API URL
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

#### Bước 4: Start/Restart PM2

```bash
cd /var/www/asset-rmg

# Nếu chưa có PM2 process
pm2 start ecosystem.config.js

# Hoặc restart nếu đã có
pm2 restart asset-rmg-api

# Hoặc delete và start lại
pm2 delete asset-rmg-api
pm2 start ecosystem.config.js
```

#### Bước 5: Kiểm tra Nginx Config

```bash
# Kiểm tra config đã có chưa
sudo grep -A 5 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking

# Nếu chưa có, thêm config (xem QUICK_FIX_NGINX.md)

# Test và reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

---

## ✅ Kiểm Tra Web App Đã Chạy

### 1. Kiểm tra PM2 Status

```bash
pm2 status
```

**Kết quả mong đợi:**
```
┌─────┬─────────────────┬─────────┬─────────┬──────────┐
│ id  │ name            │ status  │ restart │ uptime   │
├─────┼─────────────────┼─────────┼─────────┼──────────┤
│ 0   │ asset-rmg-api  │ online  │ 0       │ 5m       │
└─────┴─────────────────┴─────────┴─────────┴──────────┘
```

### 2. Kiểm tra PM2 Logs

```bash
pm2 logs asset-rmg-api --lines 30
```

**Kết quả mong đợi:**
```
[NestApplication] Nest application successfully started
[NestApplication] Mapped {/api/departments, GET} route
[NestApplication] Mapped {/api/assets, GET} route
...
```

### 3. Kiểm tra Port 4001

```bash
sudo netstat -tlnp | grep 4001
```

**Kết quả mong đợi:**
```
tcp  0  0  0.0.0.0:4001  0.0.0.0:*  LISTEN  12345/node
```

### 4. Test API

```bash
# Test API endpoint
curl http://localhost:4001/api/departments

# Hoặc qua Nginx
curl http://localhost/asset_rmg/api/departments
```

**Kết quả mong đợi:** JSON data hoặc `[]` (nếu chưa có data)

### 5. Test Frontend

```bash
# Kiểm tra file frontend đã build
ls -la /var/www/asset-rmg/frontend/dist/index.html

# Test qua Nginx
curl -I http://localhost/asset_rmg
```

**Kết quả mong đợi:** HTTP 200 OK

### 6. Truy cập từ Browser

- **Frontend:** http://27.71.16.15/asset_rmg
- **API:** http://27.71.16.15/asset_rmg/api/departments

---

## 🔧 Troubleshooting

### PM2 không start được

```bash
# Xem logs chi tiết
pm2 logs asset-rmg-api --err

# Kiểm tra file build có tồn tại không
ls -la /var/www/asset-rmg/backend/dist/src/main.js

# Kiểm tra .env file
cat /var/www/asset-rmg/backend/.env

# Kiểm tra database connection
cd /var/www/asset-rmg/backend
npx prisma db pull
```

### Frontend không hiển thị

```bash
# Kiểm tra frontend đã build chưa
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx config
sudo nginx -t
sudo grep -A 10 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking

# Kiểm tra permissions
sudo chown -R www-data:www-data /var/www/asset-rmg/frontend/dist
```

### API trả về 404

```bash
# Kiểm tra PM2 đang chạy
pm2 status

# Kiểm tra backend logs
pm2 logs asset-rmg-api

# Test trực tiếp backend (không qua Nginx)
curl http://localhost:4001/api/departments

# Kiểm tra Nginx proxy config
sudo grep -A 5 "location /asset_rmg/api" /etc/nginx/sites-available/it-request-tracking
```

### Database connection error

```bash
# Kiểm tra PostgreSQL đang chạy
sudo systemctl status postgresql

# Test connection
psql -U asset_user -d asset_rmg_db -h localhost

# Kiểm tra DATABASE_URL trong .env
cat /var/www/asset-rmg/backend/.env | grep DATABASE_URL
```

---

## 📝 Các Lệnh Thường Dùng

### Restart App

```bash
cd /var/www/asset-rmg
pm2 restart asset-rmg-api
```

### Xem Logs

```bash
# Logs real-time
pm2 logs asset-rmg-api

# Logs 50 dòng cuối
pm2 logs asset-rmg-api --lines 50

# Chỉ errors
pm2 logs asset-rmg-api --err
```

### Stop App

```bash
pm2 stop asset-rmg-api
```

### Delete App

```bash
pm2 delete asset-rmg-api
```

### Rebuild và Restart

```bash
cd /var/www/asset-rmg

# Build backend
cd backend && npm run build && cd ..

# Build frontend
cd frontend && export VITE_API_URL="http://27.71.16.15/asset_rmg/api" && npm run build && cd ..

# Restart PM2
pm2 restart asset-rmg-api

# Reload Nginx
sudo systemctl reload nginx
```

---

## 🎯 Quick Commands

```bash
# Tất cả trong một
cd /var/www/asset-rmg && \
cd backend && npm run build && cd .. && \
cd frontend && export VITE_API_URL="http://27.71.16.15/asset_rmg/api" && npm run build && cd .. && \
pm2 restart asset-rmg-api && \
sudo systemctl reload nginx
```
