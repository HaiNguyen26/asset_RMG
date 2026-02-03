# 🚀 Hướng Dẫn Chạy Web App Asset RMG

## 📋 Tổng Quan

Hướng dẫn này sẽ giúp bạn chạy web app Asset RMG trên server từ đầu đến cuối.

## ⚡ Cách Nhanh Nhất - Dùng Script Tự Động

### Bước 1: Pull Script Mới

```bash
cd /var/www/asset-rmg
git pull origin main
```

### Bước 2: Chạy Script Tự Động

```bash
# Cho phép script chạy
chmod +x START_WEB_APP.sh

# Chạy script (sẽ tự động làm tất cả)
sudo ./START_WEB_APP.sh
```

Script sẽ tự động:
1. ✅ Pull code mới nhất
2. ✅ Setup và build backend
3. ✅ Setup và build frontend
4. ✅ Thêm Nginx config (nếu chưa có)
5. ✅ Start PM2
6. ✅ Reload Nginx
7. ✅ Kiểm tra ứng dụng

---

## 📝 Cách Thủ Công - Từng Bước

Nếu muốn làm từng bước để hiểu rõ hơn:

### Bước 1: Pull Code Mới Nhất

```bash
cd /var/www/asset-rmg
git pull origin main
```

### Bước 2: Setup Backend

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra file .env
ls -la .env

# Nếu chưa có, tạo file .env
cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF

# Cài đặt dependencies
npm install

# Generate Prisma Client
npx prisma generate

# Chạy migrations
npx prisma migrate deploy

# Build backend
npm run build

# Kiểm tra build thành công
ls -la dist/main.js
```

### Bước 3: Setup Frontend

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt dependencies
npm install

# Build frontend
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
ls -la dist/index.html
```

### Bước 4: Thêm Nginx Config (nếu chưa có)

```bash
# Kiểm tra config đã có chưa
sudo grep -A 3 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking

# Nếu không có kết quả, chạy script tự động
cd /var/www/asset-rmg
chmod +x add-nginx-config.sh
sudo ./add-nginx-config.sh

# Hoặc thêm thủ công (xem ADD_NGINX_CONFIG.md)
```

### Bước 5: Start PM2

```bash
cd /var/www/asset-rmg

# Dừng process cũ nếu có
pm2 delete asset-rmg-api 2>/dev/null || true

# Start với ecosystem.config.js
pm2 start ecosystem.config.js

# Lưu PM2 config
pm2 save

# Kiểm tra status
pm2 status
```

### Bước 6: Reload Nginx

```bash
# Test cấu hình
sudo nginx -t

# Reload nếu test thành công
sudo systemctl reload nginx
```

### Bước 7: Kiểm Tra

```bash
# Kiểm tra PM2
pm2 status
pm2 logs asset-rmg-api --lines 20

# Test backend
curl http://localhost:4001/api

# Test frontend (từ browser)
# http://27.71.16.15/asset_rmg
```

---

## 🔍 Kiểm Tra Sau Khi Chạy

### 1. Kiểm Tra PM2

```bash
pm2 status
```

**Kết quả mong đợi:**
```
┌─────┬──────────────────┬─────────┬─────────┬──────────┐
│ id  │ name             │ status  │ restart │ uptime   │
├─────┼──────────────────┼─────────┼─────────┼──────────┤
│ 0   │ asset-rmg-api    │ online  │ 0       │ 5m       │
└─────┴──────────────────┴─────────┴─────────┴──────────┘
```

### 2. Kiểm Tra Backend

```bash
# Test API
curl http://localhost:4001/api

# Xem logs
pm2 logs asset-rmg-api
```

### 3. Kiểm Tra Frontend

```bash
# Kiểm tra file tồn tại
ls -la /var/www/asset-rmg/frontend/dist/index.html

# Truy cập từ browser
# http://27.71.16.15/asset_rmg
```

### 4. Kiểm Tra Nginx

```bash
# Kiểm tra config
sudo grep -A 3 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking

# Kiểm tra Nginx status
sudo systemctl status nginx
```

---

## 🚨 Troubleshooting

### Backend không chạy được

```bash
# Xem logs chi tiết
pm2 logs asset-rmg-api --err

# Kiểm tra port 4001 có bị chiếm không
sudo netstat -tlnp | grep 4001

# Kiểm tra file .env
cat /var/www/asset-rmg/backend/.env

# Kiểm tra database connection
cd /var/www/asset-rmg/backend
npx prisma db pull
```

### Frontend không load được

```bash
# Kiểm tra file dist
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx logs
sudo tail -f /var/log/nginx/error.log

# Kiểm tra permissions
sudo chown -R www-data:www-data /var/www/asset-rmg/frontend/dist
```

### Build failed

```bash
# Backend build failed
cd /var/www/asset-rmg/backend
npm run build 2>&1 | tee build.log
# Xem file build.log để tìm lỗi

# Frontend build failed
cd /var/www/asset-rmg/frontend
npm run build 2>&1 | tee build.log
# Xem file build.log để tìm lỗi
```

### PM2 không start được

```bash
# Kiểm tra file ecosystem.config.js
cat /var/www/asset-rmg/ecosystem.config.js

# Kiểm tra file main.js tồn tại
ls -la /var/www/asset-rmg/backend/dist/main.js

# Start thủ công để xem lỗi
cd /var/www/asset-rmg/backend
node dist/main.js
```

---

## 📊 Các Lệnh Quản Lý Thường Dùng

### PM2 Commands

```bash
# Xem status
pm2 status

# Xem logs
pm2 logs asset-rmg-api

# Xem logs real-time
pm2 logs asset-rmg-api --lines 50

# Restart
pm2 restart asset-rmg-api

# Stop
pm2 stop asset-rmg-api

# Start
pm2 start asset-rmg-api

# Delete
pm2 delete asset-rmg-api

# Xem thông tin chi tiết
pm2 describe asset-rmg-api
```

### Nginx Commands

```bash
# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx

# Restart
sudo systemctl restart nginx

# Status
sudo systemctl status nginx

# Xem logs
sudo tail -f /var/log/nginx/error.log
```

---

## ✅ Checklist

Sau khi chạy, đảm bảo:

- [ ] Code đã được pull mới nhất
- [ ] Backend đã build thành công (`dist/main.js` tồn tại)
- [ ] Frontend đã build thành công (`dist/index.html` tồn tại)
- [ ] Nginx config đã được thêm
- [ ] PM2 đang chạy (`pm2 status` hiển thị `online`)
- [ ] Backend phản hồi (`curl http://localhost:4001/api`)
- [ ] Frontend truy cập được (`http://27.71.16.15/asset_rmg`)

---

## 🌐 Truy Cập Ứng Dụng

Sau khi hoàn thành tất cả các bước:

- **Frontend**: http://27.71.16.15/asset_rmg
- **Backend API**: http://27.71.16.15/asset_rmg/api

---

## 💡 Tips

1. **Luôn backup** trước khi thay đổi config
2. **Test Nginx config** trước khi reload: `sudo nginx -t`
3. **Xem logs** khi có lỗi: `pm2 logs asset-rmg-api`
4. **Kiểm tra port** nếu không kết nối được: `sudo netstat -tlnp | grep 4001`
5. **Giữ file .env** an toàn, không commit lên Git

---

## 📞 Nếu Vẫn Gặp Lỗi

1. Xem logs chi tiết: `pm2 logs asset-rmg-api --err`
2. Kiểm tra Nginx logs: `sudo tail -f /var/log/nginx/error.log`
3. Kiểm tra database connection
4. Kiểm tra file permissions
5. Kiểm tra Node.js version: `node -v` (cần >= 20.19)
