# 🚀 Hướng dẫn Deploy lên Server - Chi tiết từng bước

## ✅ Bước 1: Đã hoàn thành
- Code đã được push lên GitHub: https://github.com/HaiNguyen26/asset_RMG.git

---

## 📥 BƯỚC 2: Pull code về server

### 2.1. SSH vào server

Mở terminal và chạy:
```bash
ssh root@27.71.16.15
```

### 2.2. Tạo thư mục project

```bash
# Tạo thư mục
mkdir -p /var/www/asset-rmg

# Di chuyển vào thư mục
cd /var/www/asset-rmg
```

### 2.3. Clone repository từ GitHub

```bash
# Clone code từ GitHub
git clone https://github.com/HaiNguyen26/asset_RMG.git .

# Kiểm tra code đã được clone
ls -la
# Bạn sẽ thấy: backend, frontend, và các file khác
```

---

## 🗄️ BƯỚC 3: Setup Database

### 3.1. Tạo Database và User

```bash
# Vào PostgreSQL
sudo -u postgres psql
```

Trong PostgreSQL shell, chạy các lệnh sau:

```sql
-- Tạo database
CREATE DATABASE asset_rmg_db;

-- Tạo user (thay 'your_secure_password' bằng password thực tế)
CREATE USER asset_user WITH PASSWORD 'your_secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

-- Connect vào database
\c asset_rmg_db

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;

-- Thoát PostgreSQL
\q
```

**Lưu ý**: Nhớ password bạn vừa đặt, sẽ cần dùng trong file .env

---

## ⚙️ BƯỚC 4: Setup Backend

### 4.0. Kiểm tra và Upgrade Node.js (QUAN TRỌNG!)

**Prisma yêu cầu Node.js >= 20.19**

```bash
# Kiểm tra Node.js version hiện tại
node --version

# Nếu version < 20.19, upgrade Node.js:
# Xóa Node.js cũ
apt-get remove -y nodejs npm

# Cài đặt Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Kiểm tra lại
node --version
npm --version
```

**Kết quả mong đợi**: `node --version` phải >= v20.19.0

### 4.1. Cài đặt dependencies

```bash
cd /var/www/asset-rmg/backend

# Xóa node_modules cũ nếu có
rm -rf node_modules package-lock.json

# Cài đặt npm packages
npm install
```

### 4.2. Tạo file .env

```bash
# Tạo file .env
nano .env
```

**Nhập nội dung sau (thay các giá trị phù hợp):**

```env
PORT=4001
DATABASE_URL=postgresql://asset_user:your_secure_password@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_here
NODE_ENV=production
```

**Giải thích:**
- `PORT=4001`: Port backend (tránh conflict với IT Request port 4000)
- `DATABASE_URL`: Thay `your_secure_password` bằng password bạn đã đặt ở bước 3.1
- `JWT_SECRET`: Đặt một chuỗi bí mật dài ít nhất 32 ký tự (ví dụ: `rmg_asset_management_secret_key_2026_very_secure`)
- `NODE_ENV=production`: Môi trường production

**Lưu file**: Nhấn `Ctrl + X`, sau đó `Y`, sau đó `Enter`

### 4.3. Generate Prisma Client

```bash
# Generate Prisma client
npx prisma generate
```

### 4.4. Chạy Migrations (tạo tables trong database)

```bash
# Chạy migrations
npx prisma migrate deploy

# Kiểm tra migrations đã chạy thành công
npx prisma migrate status
```

**Kết quả mong đợi**: Tất cả migrations đều "Applied"

### 4.5. Seed data (tùy chọn - tạo dữ liệu mẫu)

```bash
# Seed categories, departments, và admin user
npx prisma db seed
```

**Lưu ý**: Sau khi seed, bạn sẽ có:
- Admin user: `employeesCode: "IT"`, password: `admin123` (hoặc password trong seed.ts)
- Categories: Laptop, Phụ kiện IT, Thiết bị Kỹ thuật
- Departments: Phòng Công nghệ, Phòng Hành chính, Phòng Kế toán

### 4.6. Build Backend

```bash
# Build backend
npm run build

# Kiểm tra build thành công
ls -la dist/
# Bạn sẽ thấy file main.js trong thư mục dist
```

---

## 🎨 BƯỚC 5: Setup Frontend

### 5.1. Cài đặt dependencies

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt npm packages
npm install
```

### 5.2. Build Frontend với API URL

```bash
# Set API URL và build
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

**Lưu ý**: Đảm bảo API URL đúng với path bạn sẽ cấu hình trong Nginx

### 5.3. Kiểm tra build thành công

```bash
# Kiểm tra thư mục dist đã được tạo
ls -la dist/
# Bạn sẽ thấy: index.html, assets/, và các file khác
```

---

## 🔄 BƯỚC 6: Chạy Backend với PM2

### 6.1. Kiểm tra PM2 đã được cài đặt

```bash
# Kiểm tra PM2
pm2 --version

# Nếu chưa có, cài đặt:
npm install -g pm2
pm2 startup
```

### 6.2. Start Backend với PM2

```bash
cd /var/www/asset-rmg

# Cách 1: Dùng ecosystem.config.js
pm2 start ecosystem.config.js

# Hoặc Cách 2: Start thủ công
cd backend
pm2 start dist/main.js --name asset-rmg-api --update-env
```

### 6.3. Lưu PM2 config và thiết lập auto-start

```bash
# Lưu PM2 processes
pm2 save

# Thiết lập auto-start khi server reboot
pm2 startup
# Chạy lệnh mà PM2 hiển thị (thường là sudo env PATH=...)
```

### 6.4. Kiểm tra Backend đang chạy

```bash
# Xem status PM2
pm2 status

# Xem logs
pm2 logs asset-rmg-api

# Test API local
curl http://localhost:4001/health
```

**Kết quả mong đợi**: 
- PM2 status hiển thị `asset-rmg-api` với status `online`
- Logs không có lỗi
- `curl` trả về `{"status":"ok"}` hoặc tương tự

---

## 🌐 BƯỚC 7: Cấu hình Nginx

### 7.1. Backup file config hiện tại

```bash
# Backup file config IT Request Tracking
cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup.$(date +%Y%m%d_%H%M%S)

# Kiểm tra backup đã tạo
ls -la /etc/nginx/sites-available/it-request-tracking.backup*
```

### 7.2. Mở file config để chỉnh sửa

```bash
# Mở file config
nano /etc/nginx/sites-available/it-request-tracking
```

### 7.3. Thêm cấu hình Asset RMG

Tìm đến cuối file, trước dấu `}` cuối cùng của block `server { ... }`, thêm các dòng sau:

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

**Lưu file**: Nhấn `Ctrl + X`, sau đó `Y`, sau đó `Enter`

### 7.4. Test và reload Nginx

```bash
# Test cấu hình Nginx (QUAN TRỌNG!)
nginx -t
```

**Nếu test thành công**, bạn sẽ thấy:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Nếu có lỗi**, kiểm tra lại file config và sửa lỗi.

```bash
# Reload Nginx
systemctl reload nginx

# Kiểm tra status
systemctl status nginx
```

---

## ✅ BƯỚC 8: Kiểm tra và Test

### 8.1. Kiểm tra Backend API

```bash
# Test API local
curl http://localhost:4001/health

# Test API qua Nginx
curl http://27.71.16.15/asset_rmg/api/health
```

**Kết quả mong đợi**: Trả về JSON response

### 8.2. Kiểm tra Frontend

Mở browser và truy cập:
```
http://27.71.16.15/asset_rmg
```

**Kiểm tra:**
- ✅ Trang login hiển thị
- ✅ Logo RMG hiển thị
- ✅ Không có lỗi trong browser console (F12)

### 8.3. Test đăng nhập

Sử dụng thông tin admin từ seed:
- **Mã nhân viên**: `IT`
- **Mật khẩu**: (xem trong file `backend/prisma/seed.ts` hoặc `admin123`)

### 8.4. Kiểm tra Database

```bash
# Vào PostgreSQL
sudo -u postgres psql -d asset_rmg_db

# Kiểm tra tables
\dt

# Kiểm tra một số dữ liệu
SELECT * FROM "AssetCategory";
SELECT * FROM "users" WHERE "employees_code" = 'IT';
SELECT COUNT(*) FROM "Department";

# Thoát
\q
```

### 8.5. Kiểm tra Logs

```bash
# PM2 logs
pm2 logs asset-rmg-api --lines 50

# Nginx error logs
tail -f /var/log/nginx/it-request-error.log

# Nginx access logs
tail -f /var/log/nginx/it-request-access.log
```

---

## 🐛 Troubleshooting

### ❌ Backend không chạy

```bash
# Xem logs chi tiết
pm2 logs asset-rmg-api --lines 100

# Restart backend
pm2 restart asset-rmg-api

# Kiểm tra port đã được sử dụng chưa
netstat -tulpn | grep 4001
```

### ❌ Database connection error

```bash
# Kiểm tra .env
cat /var/www/asset-rmg/backend/.env

# Test database connection
sudo -u postgres psql -d asset_rmg_db -c "SELECT 1;"

# Kiểm tra user và password
sudo -u postgres psql -c "\du"
```

### ❌ Frontend không load

```bash
# Kiểm tra build
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx config
nginx -t

# Xem Nginx error logs
tail -f /var/log/nginx/it-request-error.log

# Kiểm tra permissions
ls -la /var/www/asset-rmg/frontend/dist/
```

### ❌ Migration failed

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra migration status
npx prisma migrate status

# Reset database (CẨN THẬN - sẽ xóa dữ liệu!)
# npx prisma migrate reset

# Hoặc chạy lại migrations
npx prisma migrate deploy

# Generate lại Prisma client
npx prisma generate
```

### ❌ 404 Not Found khi truy cập /asset_rmg

```bash
# Kiểm tra Nginx config có đúng không
grep -A 10 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking

# Kiểm tra file dist có tồn tại không
ls -la /var/www/asset-rmg/frontend/dist/index.html

# Reload Nginx
systemctl reload nginx
```

---

## 📝 Checklist hoàn thành

- [ ] Code đã được pull về server
- [ ] Database đã được tạo (`asset_rmg_db`)
- [ ] User database đã được tạo (`asset_user`)
- [ ] File `.env` đã được tạo với đúng thông tin
- [ ] Prisma client đã được generate
- [ ] Migrations đã chạy thành công
- [ ] Seed data đã chạy (nếu cần)
- [ ] Backend đã build thành công
- [ ] Frontend đã build với đúng API URL
- [ ] PM2 đã start backend
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

## 🔄 Update sau này

Khi có code mới:

```bash
# SSH vào server
ssh root@27.71.16.15

# Pull code mới
cd /var/www/asset-rmg
git pull origin main

# Update backend
cd backend
npm install --production
npm run build
pm2 restart asset-rmg-api

# Update frontend
cd ../frontend
npm install --production
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Chạy migrations nếu có
cd ../backend
npx prisma migrate deploy

# Reload Nginx
systemctl reload nginx
```

---

**Chúc bạn deploy thành công!** 🚀
