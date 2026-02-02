# 📝 Hướng dẫn Deploy từng bước - Asset RMG

## 🎯 Mục tiêu
1. ✅ Đẩy code lên GitHub
2. ✅ Pull code về server
3. ✅ Triển khai và migrate database

---

## 📤 BƯỚC 1: Đẩy code lên GitHub

### 1.1. Khởi tạo Git repository (nếu chưa có)

Mở terminal/PowerShell tại thư mục dự án:

```bash
cd d:\IT-LIST-RMG

# Khởi tạo git repository
git init
git branch -M main
```

### 1.2. Thêm remote repository

```bash
# Thêm remote GitHub
git remote add origin https://github.com/HaiNguyen26/asset_RMG.git

# Nếu đã có remote, xóa và thêm lại
git remote remove origin
git remote add origin https://github.com/HaiNguyen26/asset_RMG.git
```

### 1.3. Add và commit code

```bash
# Xem các file sẽ được commit
git status

# Add tất cả các file (trừ những file trong .gitignore)
git add .

# Commit với message
git commit -m "Initial commit: Asset RMG Management System"
```

### 1.4. Push lên GitHub

```bash
# Push lên GitHub (lần đầu dùng --force nếu repo đã có code)
git push -u origin main --force

# Hoặc nếu repo trống
git push -u origin main
```

### 1.5. Kiểm tra

Truy cập: https://github.com/HaiNguyen26/asset_RMG để xem code đã được push.

---

## 📥 BƯỚC 2: Pull code về server

### 2.1. SSH vào server

```bash
ssh root@27.71.16.15
```

### 2.2. Tạo thư mục project (nếu chưa có)

```bash
# Tạo thư mục
mkdir -p /var/www/asset-rmg
cd /var/www/asset-rmg
```

### 2.3. Clone repository

```bash
# Nếu chưa clone
git clone https://github.com/HaiNguyen26/asset_RMG.git .

# Hoặc nếu đã clone rồi, pull code mới
git pull origin main
```

### 2.4. Kiểm tra code đã được pull

```bash
ls -la
# Kiểm tra có các thư mục: backend, frontend, ...
```

---

## 🚀 BƯỚC 3: Triển khai và Setup

### 3.1. Setup Backend

```bash
cd /var/www/asset-rmg/backend

# Cài đặt dependencies
npm install

# Tạo file .env
nano .env
```

**Nội dung file `.env`:**
```env
PORT=4001
DATABASE_URL=postgresql://asset_user:your_password@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars
NODE_ENV=production
```

**Lưu ý**: Thay `your_password` và `your_jwt_secret_key_change_in_production_min_32_chars` bằng giá trị thực tế.

### 3.2. Setup Database

#### 3.2.1. Tạo database và user

```bash
# Vào PostgreSQL
sudo -u postgres psql
```

Trong PostgreSQL shell, chạy:

```sql
-- Tạo database
CREATE DATABASE asset_rmg_db;

-- Tạo user
CREATE USER asset_user WITH PASSWORD 'your_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

-- Connect vào database và grant schema privileges
\c asset_rmg_db
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;

-- Thoát
\q
```

#### 3.2.2. Generate Prisma Client

```bash
cd /var/www/asset-rmg/backend
npx prisma generate
```

#### 3.2.3. Chạy Migrations

```bash
# Chạy migrations để tạo tables
npx prisma migrate deploy

# Kiểm tra migrations đã chạy
npx prisma migrate status
```

#### 3.2.4. Seed data (tùy chọn)

```bash
# Seed dữ liệu mẫu (categories, departments, admin user)
npx prisma db seed
```

### 3.3. Build Backend

```bash
cd /var/www/asset-rmg/backend
npm run build

# Kiểm tra build thành công
ls -la dist/
```

### 3.4. Setup Frontend

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt dependencies
npm install

# Build frontend với API URL
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
ls -la dist/
```

### 3.5. Setup PM2

```bash
cd /var/www/asset-rmg

# Start backend với PM2
pm2 start ecosystem.config.js

# Hoặc start thủ công
cd backend
pm2 start dist/main.js --name asset-rmg-api --update-env

# Lưu PM2 config
pm2 save

# Thiết lập auto-start khi reboot
pm2 startup
```

### 3.6. Kiểm tra Backend đang chạy

```bash
# Kiểm tra PM2 status
pm2 status

# Kiểm tra logs
pm2 logs asset-rmg-api

# Test API
curl http://localhost:4001/health
```

---

## 🌐 BƯỚC 4: Cấu hình Nginx

### 4.1. Backup file config hiện tại

```bash
cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup.$(date +%Y%m%d_%H%M%S)
```

### 4.2. Mở file config

```bash
nano /etc/nginx/sites-available/it-request-tracking
```

### 4.3. Thêm cấu hình Asset RMG

Tìm đến cuối file, trước dấu `}` cuối cùng của block `server { ... }`, thêm:

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

### 4.4. Test và reload Nginx

```bash
# Test cấu hình
nginx -t

# Nếu test OK, reload Nginx
systemctl reload nginx

# Kiểm tra status
systemctl status nginx
```

---

## ✅ BƯỚC 5: Kiểm tra và Test

### 5.1. Kiểm tra Backend API

```bash
# Test local
curl http://localhost:4001/health

# Test qua Nginx
curl http://27.71.16.15/asset_rmg/api/health
```

### 5.2. Kiểm tra Frontend

Mở browser và truy cập: **http://27.71.16.15/asset_rmg**

### 5.3. Kiểm tra Database

```bash
# Vào PostgreSQL
sudo -u postgres psql -d asset_rmg_db

# Kiểm tra tables
\dt

# Kiểm tra một số tables
SELECT * FROM "AssetCategory";
SELECT * FROM "users" WHERE "employees_code" = 'IT';

# Thoát
\q
```

### 5.4. Kiểm tra Logs

```bash
# PM2 logs
pm2 logs asset-rmg-api --lines 50

# Nginx logs
tail -f /var/log/nginx/it-request-error.log
tail -f /var/log/nginx/it-request-access.log
```

---

## 🔄 BƯỚC 6: Update sau này

Khi có code mới:

```bash
# 1. Pull code mới
cd /var/www/asset-rmg
git pull origin main

# 2. Update backend
cd backend
npm install --production
npm run build
pm2 restart asset-rmg-api

# 3. Update frontend
cd ../frontend
npm install --production
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# 4. Chạy migrations nếu có
cd ../backend
npx prisma migrate deploy

# 5. Reload Nginx
systemctl reload nginx
```

---

## 🐛 Troubleshooting

### Backend không chạy
```bash
pm2 logs asset-rmg-api --lines 50
pm2 restart asset-rmg-api
```

### Database connection error
```bash
# Kiểm tra .env
cat /var/www/asset-rmg/backend/.env

# Test database connection
sudo -u postgres psql -d asset_rmg_db -c "SELECT 1;"
```

### Frontend không load
```bash
# Kiểm tra build
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx
nginx -t
tail -f /var/log/nginx/it-request-error.log
```

### Migration failed
```bash
cd /var/www/asset-rmg/backend
npx prisma migrate status
npx prisma migrate deploy
npx prisma generate
```

---

## 📝 Checklist

- [ ] Code đã được push lên GitHub
- [ ] Code đã được pull về server
- [ ] Database đã được tạo
- [ ] Migrations đã chạy thành công
- [ ] Backend đã build và chạy với PM2
- [ ] Frontend đã build với đúng API URL
- [ ] Nginx đã được cấu hình
- [ ] Backend API test OK
- [ ] Frontend load được trên browser
- [ ] Database có dữ liệu seed (nếu cần)

---

**Hoàn thành!** 🎉

Truy cập ứng dụng tại: **http://27.71.16.15/asset_rmg**
