# 🔧 Fix Main.js Path Issue

## 🚨 Vấn Đề

File `dist/main.js` không tồn tại, nhưng file có thể ở `dist/src/main.js`.

## ✅ Giải Pháp

### Cách 1: Sửa ecosystem.config.js (Khuyến nghị)

File `main.js` được NestJS build vào `dist/src/main.js` thay vì `dist/main.js`.

**Sửa file `ecosystem.config.js`:**

```javascript
module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',
      script: './backend/dist/src/main.js',  // ✅ Thêm /src/
      cwd: '/var/www/asset-rmg',
      // ...
    },
  ],
}
```

### Cách 2: Sửa tsconfig.json để build ra dist/main.js trực tiếp

Nếu muốn file ở `dist/main.js`, sửa `tsconfig.json`:

```json
{
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./",  // ✅ Thêm dòng này
    // ... các config khác
  }
}
```

**Lưu ý:** Cách này có thể gây lỗi với các imports khác.

## 🔍 Kiểm Tra

Trên server, chạy:

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra file ở đâu
find dist -name "main.js" -type f

# Nếu thấy dist/src/main.js
ls -lh dist/src/main.js

# Sửa ecosystem.config.js
cd /var/www/asset-rmg
nano ecosystem.config.js
# Đổi: script: './backend/dist/main.js'
# Thành: script: './backend/dist/src/main.js'
```

## ✅ Sau Khi Sửa

```bash
cd /var/www/asset-rmg

# Pull code mới (nếu đã commit)
git pull origin main

# Restart PM2
pm2 restart asset-rmg-api

# Hoặc start lại
pm2 delete asset-rmg-api
pm2 start ecosystem.config.js
pm2 save
```
