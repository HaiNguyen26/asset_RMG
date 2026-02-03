# 🚀 Start PM2 Đúng Cách

## ❌ Lỗi hiện tại

```
[PM2][ERROR] File ecosystem.config.js not found
```

**Nguyên nhân**: File `ecosystem.config.js` nằm ở root project (`/var/www/asset-rmg/`), không phải trong `backend/`.

## ✅ Giải pháp

### Cách 1: Chạy từ root project (Khuyến nghị)

```bash
# Về thư mục root của project
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

### Cách 2: Chỉ định đường dẫn đầy đủ

```bash
# Từ bất kỳ đâu
pm2 start /var/www/asset-rmg/ecosystem.config.js

# Hoặc
pm2 start /var/www/asset-rmg/backend/dist/main.js --name asset-rmg-api --update-env
```

### Cách 3: Kiểm tra file có tồn tại không

```bash
# Kiểm tra file ecosystem.config.js
ls -la /var/www/asset-rmg/ecosystem.config.js

# Nếu không có, pull code mới
cd /var/www/asset-rmg
git pull origin main

# Kiểm tra lại
ls -la ecosystem.config.js
```

---

## 📝 Các bước đầy đủ

### 1. Đảm bảo đã build backend

```bash
cd /var/www/asset-rmg/backend
npm run build

# Kiểm tra build thành công
ls -la dist/main.js
```

### 2. Start với PM2 từ root project

```bash
cd /var/www/asset-rmg

# Kiểm tra file ecosystem.config.js có tồn tại
ls -la ecosystem.config.js

# Start với PM2
pm2 start ecosystem.config.js

# Hoặc start thủ công
pm2 start backend/dist/main.js --name asset-rmg-api --update-env --env production
```

### 3. Lưu và thiết lập auto-start

```bash
# Lưu PM2 processes
pm2 save

# Thiết lập auto-start khi reboot
pm2 startup
# Chạy lệnh mà PM2 hiển thị (thường là sudo env PATH=...)
```

### 4. Kiểm tra

```bash
# Xem status
pm2 status

# Xem logs
pm2 logs asset-rmg-api --lines 50

# Test API
curl http://localhost:4001/health
```

---

## 🐛 Troubleshooting

### File ecosystem.config.js không tồn tại

```bash
cd /var/www/asset-rmg

# Pull code mới
git pull origin main

# Kiểm tra lại
ls -la ecosystem.config.js
```

### PM2 không start được

```bash
# Kiểm tra file main.js có tồn tại không
ls -la /var/www/asset-rmg/backend/dist/main.js

# Nếu không có, build lại
cd /var/www/asset-rmg/backend
npm run build
```

### Port 4001 đã được sử dụng

```bash
# Kiểm tra port
netstat -tulpn | grep 4001

# Xóa process cũ
pm2 delete asset-rmg-api

# Start lại
pm2 start ecosystem.config.js
```

---

## ✅ Checklist

- [ ] Đã build backend thành công (`dist/main.js` tồn tại)
- [ ] File `ecosystem.config.js` có trong `/var/www/asset-rmg/`
- [ ] Đang ở đúng thư mục (`/var/www/asset-rmg`) khi chạy PM2
- [ ] PM2 đã start thành công
- [ ] PM2 status hiển thị `asset-rmg-api` với status `online`
- [ ] API test OK: `curl http://localhost:4001/health`
