# 🔨 Build Backend Trước Khi Start PM2

## ❌ Lỗi hiện tại

```
[PM2][ERROR] Error: Script not found: /var/www/asset-rmg/backend/dist/main.js
```

**Nguyên nhân**: Backend chưa được build, file `main.js` không tồn tại.

## ✅ Giải pháp: Build Backend trước

### Bước 1: Build Backend

```bash
cd /var/www/asset-rmg/backend

# Build backend
npm run build

# Kiểm tra build thành công
ls -la dist/
# Phải có file: main.js
```

### Bước 2: Kiểm tra file main.js

```bash
# Kiểm tra file đã được tạo
ls -la /var/www/asset-rmg/backend/dist/main.js

# Xem thông tin file
file /var/www/asset-rmg/backend/dist/main.js
```

### Bước 3: Start với PM2

```bash
cd /var/www/asset-rmg

# Start với PM2
pm2 start ecosystem.config.js

# Hoặc start thủ công
pm2 start backend/dist/main.js --name asset-rmg-api --update-env

# Lưu PM2 config
pm2 save

# Kiểm tra status
pm2 status
pm2 logs asset-rmg-api
```

---

## 🔍 Nếu build bị lỗi

### Kiểm tra dependencies

```bash
cd /var/www/asset-rmg/backend

# Cài đặt dependencies
npm install

# Build lại
npm run build
```

### Kiểm tra Prisma client đã generate chưa

```bash
cd /var/www/asset-rmg/backend

# Generate Prisma client
npx prisma generate

# Build lại
npm run build
```

### Kiểm tra file .env

```bash
# Đảm bảo file .env có đầy đủ thông tin
cat /var/www/asset-rmg/backend/.env
```

---

## 📝 Checklist trước khi start PM2

- [ ] Backend dependencies đã được cài (`npm install`)
- [ ] Prisma client đã được generate (`npx prisma generate`)
- [ ] File `.env` đã được tạo với đầy đủ thông tin
- [ ] Backend đã được build (`npm run build`)
- [ ] File `dist/main.js` tồn tại
- [ ] File `ecosystem.config.js` tồn tại ở root project

---

## ✅ Sau khi build thành công

```bash
cd /var/www/asset-rmg

# Start PM2
pm2 start ecosystem.config.js

# Kiểm tra
pm2 status
pm2 logs asset-rmg-api --lines 20

# Test API
curl http://localhost:4001/health
```

---

## 🐛 Troubleshooting

### Build failed với lỗi TypeScript

```bash
cd /var/www/asset-rmg/backend

# Xóa node_modules và cài lại
rm -rf node_modules package-lock.json
npm install

# Build lại
npm run build
```

### Build thành công nhưng PM2 vẫn báo không tìm thấy

```bash
# Kiểm tra đường dẫn trong ecosystem.config.js
cat /var/www/asset-rmg/ecosystem.config.js

# Kiểm tra file có tồn tại không
ls -la /var/www/asset-rmg/backend/dist/main.js

# Nếu không có, build lại
cd /var/www/asset-rmg/backend
npm run build
```
