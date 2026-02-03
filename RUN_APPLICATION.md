# 🚀 Hướng Dẫn Chạy Ứng Dụng Trên Server

## ✅ Checklist Trước Khi Chạy

### 1. Kiểm tra trên Server

```bash
# SSH vào server
ssh root@27.71.16.15

# Kiểm tra Node.js version (cần >= 20.19)
node -v

# Kiểm tra PostgreSQL đang chạy
sudo systemctl status postgresql

# Kiểm tra PM2 đã cài
pm2 --version

# Kiểm tra Nginx đang chạy
sudo systemctl status nginx
```

### 2. Pull Code Mới Nhất

```bash
cd /var/www/asset-rmg

# Pull code từ GitHub
git pull origin main

# Kiểm tra code đã được pull
git log --oneline -5
```

### 3. Cấu Hình Backend

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra file .env tồn tại
ls -la .env

# Nếu chưa có, tạo file .env
cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF

# Cài đặt dependencies (nếu chưa có hoặc có thay đổi)
npm install

# Generate Prisma Client
npx prisma generate

# Chạy migrations (nếu có migrations mới)
npx prisma migrate deploy

# Build backend
npm run build

# Kiểm tra build thành công
ls -la dist/main.js
```

### 4. Cấu Hình Frontend

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt dependencies (nếu chưa có hoặc có thay đổi)
npm install

# Build frontend với API URL
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Kiểm tra build thành công
ls -la dist/index.html
```

### 5. Cấu Hình Nginx

```bash
# Kiểm tra file config đã được thêm vào nginx chưa
sudo cat /etc/nginx/sites-available/default | grep -A 5 "asset_rmg"

# Nếu chưa có, thêm config vào file nginx chính
# (File nginx-asset-rmg.conf đã có sẵn trong repo)
sudo nano /etc/nginx/sites-available/default

# Hoặc thêm vào file riêng và link
sudo cp /var/www/asset-rmg/nginx-asset-rmg.conf /etc/nginx/sites-available/asset-rmg
sudo ln -sf /etc/nginx/sites-available/asset-rmg /etc/nginx/sites-enabled/

# Test Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 6. Khởi Động Backend với PM2

```bash
cd /var/www/asset-rmg

# Kiểm tra PM2 đã có process nào chạy chưa
pm2 list

# Nếu đã có process cũ, dừng và xóa
pm2 delete asset-rmg-api 2>/dev/null || true

# Start backend với PM2
pm2 start ecosystem.config.js

# Kiểm tra status
pm2 status

# Xem logs
pm2 logs asset-rmg-api --lines 50

# Lưu PM2 config để tự động restart khi server reboot
pm2 save
pm2 startup
```

### 7. Kiểm Tra Ứng Dụng

```bash
# Test backend API
curl http://localhost:4001/api/health || echo "Backend chưa có endpoint /health"

# Test từ bên ngoài (nếu có domain)
curl http://27.71.16.15/asset_rmg/api/health || echo "Kiểm tra Nginx config"

# Kiểm tra frontend
curl -I http://27.71.16.15/asset_rmg/ | head -5
```

## 🌐 Truy Cập Ứng Dụng

Sau khi hoàn thành các bước trên, truy cập:

- **Frontend**: http://27.71.16.15/asset_rmg
- **Backend API**: http://27.71.16.15/asset_rmg/api

## 🔍 Troubleshooting

### Backend không chạy được

```bash
# Xem logs chi tiết
pm2 logs asset-rmg-api --err

# Kiểm tra port 4001 có bị chiếm không
sudo netstat -tlnp | grep 4001

# Kiểm tra database connection
cd /var/www/asset-rmg/backend
npx prisma db pull
```

### Frontend không load được

```bash
# Kiểm tra file dist có tồn tại không
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx logs
sudo tail -f /var/log/nginx/error.log

# Kiểm tra permissions
sudo chown -R www-data:www-data /var/www/asset-rmg/frontend/dist
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

## 📝 Lệnh Nhanh (Quick Commands)

```bash
# Pull và deploy nhanh
cd /var/www/asset-rmg && \
git pull origin main && \
cd backend && npm install && npx prisma generate && npm run build && \
cd ../frontend && npm install && export VITE_API_URL="http://27.71.16.15/asset_rmg/api" && npm run build && \
cd .. && pm2 restart asset-rmg-api && \
sudo systemctl reload nginx
```

## ✅ Sau Khi Chạy Thành Công

1. ✅ Backend chạy trên port 4001 (PM2)
2. ✅ Frontend được serve qua Nginx tại `/asset_rmg`
3. ✅ API proxy qua Nginx tại `/asset_rmg/api`
4. ✅ Database migrations đã chạy
5. ✅ PM2 tự động restart khi crash
6. ✅ Nginx cache static files
