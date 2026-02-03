# 🔧 Fix DATABASE_URL Environment Variable Issue

## 🚨 Vấn Đề

PM2 không đọc được `DATABASE_URL` từ file `.env`, gây lỗi:
```
Error: DATABASE_URL environment variable is not set or invalid
```

## ✅ Giải Pháp

### Cách 1: Load .env trong ecosystem.config.js (Khuyến nghị)

PM2 không tự động load file `.env`. Cần load thủ công trong `ecosystem.config.js`.

**Sửa file `ecosystem.config.js`:**

```javascript
require('dotenv').config({ path: './backend/.env' });

module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',
      script: './backend/dist/src/main.js',
      cwd: '/var/www/asset-rmg',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 4001,
        DATABASE_URL: process.env.DATABASE_URL,
        JWT_SECRET: process.env.JWT_SECRET,
      },
      error_file: '/var/log/pm2/asset-rmg-error.log',
      out_file: '/var/log/pm2/asset-rmg-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
}
```

### Cách 2: Đảm bảo file .env tồn tại và đúng format

**Kiểm tra file .env:**

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra file tồn tại
ls -la .env

# Xem nội dung (KHÔNG hiển thị password)
cat .env | grep -v PASSWORD
```

**Nội dung file .env phải có:**

```env
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
```

**Lưu ý:** 
- KHÔNG có dấu ngoặc kép `"` quanh giá trị
- KHÔNG có khoảng trắng thừa
- Mỗi biến trên một dòng

### Cách 3: Set environment variables trực tiếp trong ecosystem.config.js

Nếu không muốn dùng file .env:

```javascript
module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',
      script: './backend/dist/src/main.js',
      cwd: '/var/www/asset-rmg',
      env: {
        NODE_ENV: 'production',
        PORT: 4001,
        DATABASE_URL: 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db',
        JWT_SECRET: 'your_jwt_secret_key_change_in_production_min_32_chars_please_change_this',
      },
      // ...
    },
  ],
}
```

**⚠️ Lưu ý:** Cách này không an toàn nếu commit lên Git. Chỉ dùng tạm thời.

## 🔍 Kiểm Tra

### Bước 1: Kiểm tra file .env

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra file tồn tại
ls -la .env

# Kiểm tra nội dung (ẩn password)
cat .env | sed 's/:.*@/:****@/g'
```

### Bước 2: Test load .env

```bash
cd /var/www/asset-rmg/backend

# Test load .env
node -e "require('dotenv').config(); console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET')"
```

### Bước 3: Restart PM2

```bash
cd /var/www/asset-rmg

# Pull code mới (nếu đã sửa ecosystem.config.js)
git pull origin main

# Restart PM2
pm2 delete asset-rmg-api
pm2 start ecosystem.config.js
pm2 save

# Kiểm tra logs
pm2 logs asset-rmg-api --lines 20
```

## 🚨 Troubleshooting

### Nếu vẫn không đọc được .env

**Kiểm tra đường dẫn:**

```bash
cd /var/www/asset-rmg

# Kiểm tra file .env có ở đúng chỗ không
ls -la backend/.env

# Test load từ root
node -e "require('dotenv').config({ path: './backend/.env' }); console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET')"
```

**Kiểm tra permissions:**

```bash
cd /var/www/asset-rmg/backend

# Set permissions
chmod 600 .env
chown root:root .env
```

### Nếu DATABASE_URL vẫn invalid

**Kiểm tra format:**

```bash
cd /var/www/asset-rmg/backend

# Xem DATABASE_URL (ẩn password)
cat .env | grep DATABASE_URL | sed 's/:.*@/:****@/g'

# Format đúng:
# DATABASE_URL=postgresql://user:password@host:port/database
```

**Test connection:**

```bash
cd /var/www/asset-rmg/backend

# Test với psql
psql "postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" -c "SELECT 1;"
```

## ✅ Quick Fix

```bash
cd /var/www/asset-rmg

# 1. Đảm bảo file .env tồn tại
cd backend
cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF

# 2. Pull code mới (nếu đã sửa ecosystem.config.js)
cd ..
git pull origin main

# 3. Restart PM2
pm2 delete asset-rmg-api
pm2 start ecosystem.config.js
pm2 save

# 4. Kiểm tra logs
pm2 logs asset-rmg-api --lines 20
```
