# 🚀 Hướng Dẫn Server - Asset RMG

## 📋 Thông Tin Server

- **Server IP**: `27.71.16.15`
- **SSH**: `ssh root@27.71.16.15`
- **Project Path**: `/var/www/asset-rmg`
- **Backend Port**: `4001`
- **Frontend URL**: `http://27.71.16.15/asset_rmg`
- **Backend API URL**: `http://27.71.16.15/asset_rmg/api`
- **GitHub Repo**: `https://github.com/HaiNguyen26/asset_RMG.git`

## 🗄️ Database

- **Database Name**: `asset_rmg_db`
- **Database User**: `asset_user`
- **Database Password**: `Hainguyen261097`
- **Connection String**: `postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db`

## ⚙️ Cấu Hình

### Backend `.env` File

**Path**: `/var/www/asset-rmg/backend/.env`

```env
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
```

### PM2 Config

**Path**: `/var/www/asset-rmg/ecosystem.config.js`

- **App Name**: `asset-rmg-api`
- **Script**: `./backend/dist/main.js`
- **Port**: `4001`

### Nginx Config

**Path**: `/etc/nginx/sites-available/it-request-tracking`

- **Location**: `/asset_rmg` (Frontend)
- **Location**: `/asset_rmg/api` (Backend API)
- **Proxy Pass**: `http://localhost:4001`

---

## 🚀 Các Lệnh Quan Trọng

### 1. Pull Code Tự Động

```bash
cd /var/www/asset-rmg
git pull origin main
```

**Script tự động:**
```bash
cd /var/www/asset-rmg
chmod +x pull-code.sh
./pull-code.sh
```

### 2. Build và Deploy Tự Động

**Script tự động (khuyến nghị):**
```bash
cd /var/www/asset-rmg
chmod +x START_WEB_APP.sh
sudo ./START_WEB_APP.sh
```

Script này sẽ tự động:
- ✅ Pull code mới nhất
- ✅ Build backend
- ✅ Build frontend
- ✅ Thêm Nginx config (nếu chưa có)
- ✅ Start PM2
- ✅ Reload Nginx

### 3. Migration Database Tự Động

```bash
cd /var/www/asset-rmg/backend
npx prisma migrate deploy
```

**Script tự động:**
```bash
cd /var/www/asset-rmg
chmod +x migrate.sh
./migrate.sh
```

### 4. Restart Ứng Dụng

```bash
# Restart PM2
cd /var/www/asset-rmg
pm2 restart asset-rmg-api

# Hoặc restart tất cả
pm2 restart all
```

### 5. Xem Logs

```bash
# PM2 logs
pm2 logs asset-rmg-api

# PM2 logs real-time
pm2 logs asset-rmg-api --lines 50

# Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### 6. Kiểm Tra Status

```bash
# PM2 status
pm2 status

# Nginx status
sudo systemctl status nginx

# PostgreSQL status
sudo systemctl status postgresql

# Kiểm tra port
sudo netstat -tlnp | grep 4001
```

---

## 📝 Quy Trình Deploy Mới

### Bước 1: Pull Code

```bash
cd /var/www/asset-rmg
git pull origin main
```

### Bước 2: Build Backend

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate deploy
npm run build
```

### Bước 3: Build Frontend

```bash
cd ../frontend
npm install
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

### Bước 4: Restart PM2

```bash
cd /var/www/asset-rmg
pm2 restart asset-rmg-api
```

### Bước 5: Reload Nginx (nếu có thay đổi config)

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔄 Quy Trình Cập Nhật Code (Quick)

**Cách nhanh nhất - Dùng script:**

```bash
cd /var/www/asset-rmg
sudo ./START_WEB_APP.sh
```

**Cách thủ công:**

```bash
# 1. Pull code
cd /var/www/asset-rmg
git pull origin main

# 2. Build backend
cd backend
npm install
npx prisma generate
npx prisma migrate deploy
npm run build

# 3. Build frontend
cd ../frontend
npm install
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# 4. Restart PM2
cd /var/www/asset-rmg
pm2 restart asset-rmg-api
```

---

## 🛠️ Các Lệnh Quản Lý PM2

```bash
# Xem status
pm2 status

# Xem logs
pm2 logs asset-rmg-api

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

# Lưu config
pm2 save

# Auto-start khi reboot
pm2 startup
```

---

## 🌐 Nginx Commands

```bash
# Test config
sudo nginx -t

# Reload (không downtime)
sudo systemctl reload nginx

# Restart
sudo systemctl restart nginx

# Status
sudo systemctl status nginx

# Xem logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

---

## 🗄️ Database Commands

```bash
# Connect vào database
sudo -u postgres psql -d asset_rmg_db

# Xem danh sách databases
sudo -u postgres psql -l

# Backup database
pg_dump -U asset_user -d asset_rmg_db > backup_$(date +%Y%m%d).sql

# Restore database
psql -U asset_user -d asset_rmg_db < backup_20240202.sql

# Prisma commands
cd /var/www/asset-rmg/backend
npx prisma generate          # Generate Prisma Client
npx prisma migrate deploy      # Chạy migrations
npx prisma studio             # Mở Prisma Studio (GUI)
npx prisma db pull            # Pull schema từ database
```

---

## 🚨 Troubleshooting

### Backend không chạy được

```bash
# Xem logs chi tiết
pm2 logs asset-rmg-api --err

# Kiểm tra port có bị chiếm không
sudo netstat -tlnp | grep 4001

# Kiểm tra file .env
cat /var/www/asset-rmg/backend/.env

# Test database connection
cd /var/www/asset-rmg/backend
npx prisma db pull

# Start thủ công để xem lỗi
cd /var/www/asset-rmg/backend
node dist/main.js
```

### Frontend không load được

```bash
# Kiểm tra file dist
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx logs
sudo tail -f /var/log/nginx/error.log

# Kiểm tra permissions
sudo chown -R www-data:www-data /var/www/asset-rmg/frontend/dist

# Kiểm tra Nginx config
sudo grep -A 5 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```

### Build failed

```bash
# Backend build failed
cd /var/www/asset-rmg/backend
npm run build 2>&1 | tee build.log
cat build.log

# Frontend build failed
cd /var/www/asset-rmg/frontend
npm run build 2>&1 | tee build.log
cat build.log

# Kiểm tra Node.js version (cần >= 20.19)
node -v
```

### Database errors

```bash
# Kiểm tra PostgreSQL đang chạy
sudo systemctl status postgresql

# Kiểm tra database và user
sudo -u postgres psql -c "\l" | grep asset_rmg_db
sudo -u postgres psql -c "\du" | grep asset_user

# Test connection
cd /var/www/asset-rmg/backend
npx prisma db execute --stdin <<< "SELECT 1;"
```

---

## 📊 Kiểm Tra Sau Deploy

```bash
# 1. Kiểm tra PM2
pm2 status | grep asset-rmg-api

# 2. Kiểm tra Backend
curl http://localhost:4001/api

# 3. Kiểm tra Frontend
curl -I http://localhost/asset_rmg

# 4. Kiểm tra Nginx
sudo nginx -t

# 5. Kiểm tra Database
cd /var/www/asset-rmg/backend
npx prisma db pull
```

---

## 🔐 Bảo Mật

### File `.env`

- **KHÔNG** commit file `.env` lên Git
- Giữ file `.env` an toàn, chỉ root mới đọc được
- Đổi `JWT_SECRET` thành chuỗi ngẫu nhiên dài >= 32 ký tự

```bash
# Set permissions cho .env
chmod 600 /var/www/asset-rmg/backend/.env
```

### Database Password

- Đổi password mặc định trong production
- Sử dụng password mạnh
- Không chia sẻ password trong code

---

## 📞 Thông Tin Liên Hệ

- **GitHub**: https://github.com/HaiNguyen26/asset_RMG.git
- **Server**: 27.71.16.15
- **Project Path**: /var/www/asset-rmg

---

## ✅ Checklist Deploy

Sau mỗi lần deploy, kiểm tra:

- [ ] Code đã được pull mới nhất
- [ ] Backend đã build thành công (`dist/main.js` tồn tại)
- [ ] Frontend đã build thành công (`dist/index.html` tồn tại)
- [ ] Migrations đã chạy (`npx prisma migrate deploy`)
- [ ] PM2 đang chạy (`pm2 status` hiển thị `online`)
- [ ] Backend phản hồi (`curl http://localhost:4001/api`)
- [ ] Frontend truy cập được (`http://27.71.16.15/asset_rmg`)
- [ ] Nginx config hợp lệ (`sudo nginx -t`)

---

## 💡 Tips

1. **Luôn backup** trước khi thay đổi lớn
2. **Test Nginx config** trước khi reload: `sudo nginx -t`
3. **Xem logs** khi có lỗi: `pm2 logs asset-rmg-api`
4. **Kiểm tra port** nếu không kết nối được
5. **Giữ file .env** an toàn, không commit lên Git
6. **Dùng script tự động** để tránh lỗi: `START_WEB_APP.sh`

---

## 🎯 Quick Reference

### Deploy mới code
```bash
cd /var/www/asset-rmg && sudo ./START_WEB_APP.sh
```

### Chỉ pull code và restart
```bash
cd /var/www/asset-rmg && git pull origin main && pm2 restart asset-rmg-api
```

### Chỉ chạy migration
```bash
cd /var/www/asset-rmg/backend && npx prisma migrate deploy
```

### Xem logs
```bash
pm2 logs asset-rmg-api --lines 50
```

### Restart app
```bash
pm2 restart asset-rmg-api
```
