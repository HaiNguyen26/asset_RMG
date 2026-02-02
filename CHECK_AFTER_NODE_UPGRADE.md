# ✅ Kiểm tra sau khi Upgrade Node.js Global

## 🔍 Bước 1: Kiểm tra Node.js version mới

```bash
# Kiểm tra version
node --version
npm --version
```

**Kết quả mong đợi**: Node.js >= v20.19.0

---

## 🔍 Bước 2: Kiểm tra IT Request App có bị ảnh hưởng không

### 2.1. Kiểm tra PM2 status

```bash
# Xem tất cả processes
pm2 list

# Kiểm tra IT Request app
pm2 status it-request-api
```

### 2.2. Restart IT Request app và kiểm tra logs

```bash
# Restart IT Request app
pm2 restart it-request-api

# Xem logs
pm2 logs it-request-api --lines 50
```

**Kiểm tra:**
- ✅ Status phải là `online`
- ✅ Không có lỗi trong logs
- ✅ App khởi động thành công

### 2.3. Test API IT Request

```bash
# Test API local
curl http://localhost:4000/health

# Test API qua Nginx
curl http://27.71.16.15/api/health
```

**Kết quả mong đợi**: Trả về JSON response (ví dụ: `{"status":"ok"}`)

### 2.4. Test Frontend IT Request

Mở browser và truy cập: `http://27.71.16.15`

**Kiểm tra:**
- ✅ Trang web load được
- ✅ Không có lỗi trong browser console (F12)

---

## ✅ Nếu IT Request App vẫn chạy OK

**Chúc mừng!** Bạn có thể tiếp tục setup Asset RMG:

```bash
cd /var/www/asset-rmg/backend

# Xóa node_modules cũ
rm -rf node_modules package-lock.json

# Cài đặt dependencies với Node.js 20
npm install

# Tiếp tục setup
npx prisma generate
npx prisma migrate deploy
npm run build
```

---

## ❌ Nếu IT Request App bị lỗi

### Option A: Rollback về Node.js 18

```bash
# 1. Xóa Node.js 20
apt-get remove -y nodejs npm

# 2. Cài lại Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 3. Kiểm tra version
node --version
# Phải là v18.x.x

# 4. Restart IT Request app
pm2 restart it-request-api

# 5. Test lại
curl http://localhost:4000/health
```

### Option B: Fix IT Request App để chạy với Node.js 20

Nếu muốn giữ Node.js 20, cần update IT Request app:

```bash
cd /var/www/it-request-tracking/server

# Update dependencies
npm install

# Rebuild
npm run build

# Restart
pm2 restart it-request-api
```

---

## 🎯 Tiếp tục Setup Asset RMG

Sau khi đảm bảo IT Request app OK, tiếp tục:

```bash
cd /var/www/asset-rmg/backend

# 1. Xóa và cài lại dependencies
rm -rf node_modules package-lock.json
npm install

# 2. Generate Prisma
npx prisma generate

# 3. Migrate database
npx prisma migrate deploy

# 4. Seed data (tùy chọn)
npx prisma db seed

# 5. Build
npm run build

# 6. Start với PM2
cd /var/www/asset-rmg
pm2 start ecosystem.config.js
pm2 save
```

---

## 📝 Checklist

- [ ] Node.js version >= 20.19.0
- [ ] IT Request app vẫn chạy OK
- [ ] IT Request API test OK
- [ ] IT Request Frontend load OK
- [ ] Asset RMG backend dependencies đã cài
- [ ] Prisma đã generate
- [ ] Migrations đã chạy
- [ ] Asset RMG backend đã build
- [ ] Asset RMG đã start với PM2

---

## 🐛 Troubleshooting

### IT Request app không start

```bash
# Xem logs chi tiết
pm2 logs it-request-api --lines 100

# Kiểm tra dependencies
cd /var/www/it-request-tracking/server
npm install

# Rebuild
npm run build

# Restart
pm2 restart it-request-api
```

### Asset RMG vẫn báo lỗi Prisma

```bash
cd /var/www/asset-rmg/backend

# Clear cache
npm cache clean --force

# Xóa và cài lại
rm -rf node_modules package-lock.json
npm install

# Generate lại Prisma
npx prisma generate
```

---

**Lưu ý**: Nếu IT Request app vẫn chạy OK với Node.js 20, thì không cần rollback. Chỉ cần tiếp tục setup Asset RMG.
