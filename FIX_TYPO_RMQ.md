# 🔧 Fix Typo: asset_rmq vs asset_rmg

## Vấn đề

Trên server có thể đang dùng `asset-rmq` hoặc `asset_rmq` thay vì `asset-rmg` hoặc `asset_rmg` ở một số nơi:
- Thư mục project: `/var/www/asset-rmq` (sai)
- Nginx config: `location /asset_rmq` (sai)
- PM2 config: `asset-rmq-api` (sai)

## Nguyên nhân

Có thể do:
1. Thư mục được tạo với tên sai ban đầu
2. Typo khi copy/paste config
3. Config được tạo thủ công với typo

## Giải pháp

### Cách 1: Dùng script tự động

```bash
cd /var/www/asset-rmg  # hoặc asset-rmq nếu đó là thư mục hiện tại

# Pull code mới
git pull origin main

# Chạy script kiểm tra
chmod +x CHECK_AND_FIX_PATH.sh
sudo ./CHECK_AND_FIX_PATH.sh
```

### Cách 2: Fix thủ công

#### 1. Kiểm tra thư mục project

```bash
# Kiểm tra thư mục hiện tại
pwd

# Nếu là asset-rmq, kiểm tra có asset-rmg không
ls -la /var/www/ | grep asset

# Nếu không có asset-rmg, có thể cần rename hoặc tạo symlink
```

#### 2. Fix Nginx Config

```bash
# Backup config
sudo cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup

# Kiểm tra typo
sudo grep -n "asset_rmq\|asset-rmq" /etc/nginx/sites-available/it-request-tracking

# Fix typo
sudo sed -i 's/asset_rmq/asset_rmg/g' /etc/nginx/sites-available/it-request-tracking
sudo sed -i 's/asset-rmq/asset-rmg/g' /etc/nginx/sites-available/it-request-tracking

# Test và reload
sudo nginx -t
sudo systemctl reload nginx
```

#### 3. Fix PM2 Config

```bash
cd /var/www/asset-rmg  # hoặc asset-rmq

# Kiểm tra typo
grep -n "asset-rmq" ecosystem.config.js

# Fix typo
sed -i 's/asset-rmq/asset-rmg/g' ecosystem.config.js

# Restart PM2
pm2 delete asset-rmq-api 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
```

#### 4. Fix Frontend Config

```bash
cd /var/www/asset-rmg/frontend

# Kiểm tra typo
grep -n "asset_rmq\|asset-rmq" vite.config.ts

# Fix typo
sed -i 's/asset_rmq/asset_rmg/g' vite.config.ts
sed -i 's/asset-rmq/asset-rmg/g' vite.config.ts

# Rebuild
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

## Kiểm tra sau khi fix

### 1. Kiểm tra Nginx config

```bash
sudo grep -A 5 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```

**Phải thấy:**
- `location /asset_rmg/api` (không phải `asset_rmq`)
- `location /asset_rmg` (không phải `asset_rmq`)

### 2. Kiểm tra PM2

```bash
pm2 status
```

**Phải thấy:**
- `asset-rmg-api` (không phải `asset-rmq-api`)

### 3. Test URLs

```bash
# Test frontend
curl -I http://localhost/asset_rmg

# Test API
curl -X POST http://localhost/asset_rmg/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"test","password":"test"}'

# Test logo
curl -I http://localhost/asset_rmg/RMG-logo.jpg
```

**Tất cả phải dùng `asset_rmg` (không phải `asset_rmq`)**

## Nếu thư mục có tên sai

Nếu thư mục trên server thực sự là `/var/www/asset-rmq`:

### Option 1: Rename thư mục (khuyến nghị)

```bash
# Stop PM2
pm2 stop asset-rmq-api 2>/dev/null || pm2 stop asset-rmg-api 2>/dev/null || true

# Rename
sudo mv /var/www/asset-rmq /var/www/asset-rmg

# Update PM2
cd /var/www/asset-rmg
pm2 delete asset-rmq-api 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
```

### Option 2: Tạo symlink

```bash
# Tạo symlink
sudo ln -s /var/www/asset-rmq /var/www/asset-rmg

# Sử dụng /var/www/asset-rmg cho tất cả config
```

## Lưu ý

1. **Luôn backup trước khi sửa:**
   ```bash
   sudo cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup
   ```

2. **Kiểm tra tất cả config:**
   - Nginx: `/etc/nginx/sites-available/it-request-tracking`
   - PM2: `ecosystem.config.js`
   - Frontend: `vite.config.ts`
   - Environment variables: `.env` files

3. **Sau khi fix, rebuild và restart:**
   ```bash
   cd /var/www/asset-rmg
   cd frontend && npm run build && cd ..
   pm2 restart asset-rmg-api
   sudo systemctl reload nginx
   ```

## Kết quả mong đợi

✅ Tất cả config dùng `asset_rmg` hoặc `asset-rmg` (không có `rmq`)  
✅ URLs hoạt động: `http://27.71.16.15/asset_rmg`  
✅ API hoạt động: `http://27.71.16.15/asset_rmg/api`  
✅ Logo hiển thị: `http://27.71.16.15/asset_rmg/RMG-logo.jpg`
