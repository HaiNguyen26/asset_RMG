# 📥 Pull Code Mới Nhất trên Server

## 🔄 Pull code từ GitHub

Trên server, chạy:

```bash
cd /var/www/asset-rmg

# Pull code mới nhất
git pull origin main

# Kiểm tra các file đã được update
git log --oneline -5
```

## ✅ Sau khi pull, tiếp tục setup

### 1. Backend

```bash
cd /var/www/asset-rmg/backend

# Cài đặt dependencies (nếu có thay đổi)
npm install

# Generate Prisma client
npx prisma generate

# Seed data (nếu chưa chạy)
npx prisma db seed

# Build
npm run build

# Restart PM2
pm2 restart asset-rmg-api
```

### 2. Frontend

```bash
cd /var/www/asset-rmg/frontend

# Cài đặt dependencies (nếu có thay đổi)
npm install

# Build với API URL
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

### 3. Reload Nginx (nếu đã cấu hình)

```bash
systemctl reload nginx
```

---

## 🔍 Kiểm tra code đã được pull

```bash
cd /var/www/asset-rmg

# Xem commit mới nhất
git log --oneline -1

# Xem các file đã thay đổi
git status

# Xem nội dung file để confirm
cat frontend/src/pages/LoginPage.tsx | head -10
```

---

## 📝 Lưu ý

- Sau khi pull, các lỗi TypeScript về unused imports sẽ được fix
- Frontend sẽ build thành công không còn warnings
- Nếu có conflicts, giải quyết trước khi tiếp tục
