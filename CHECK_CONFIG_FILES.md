# 🔍 Kiểm Tra File Config - Phân Biệt Asset RMG và IT Request Tracking

## 📋 Tổng Quan

Trên server có **2 ứng dụng**:
1. **IT Request Tracking** (app cũ) - Port 4000
2. **Asset RMG** (app mới) - Port 4001

## ✅ File Config Đúng Cho Asset RMG

### 1. PM2 Config (`ecosystem.config.js`)

**File**: `/var/www/asset-rmg/ecosystem.config.js`

```javascript
module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',  // ✅ Tên đúng
      script: './backend/dist/main.js',  // ✅ Path đúng
      cwd: '/var/www/asset-rmg',  // ✅ Working directory đúng
      env: {
        NODE_ENV: 'production',
        PORT: 4001,  // ✅ Port đúng (khác với it-request-tracking là 4000)
      },
    },
  ],
}
```

**Kiểm tra trên server:**
```bash
cd /var/www/asset-rmg
cat ecosystem.config.js | grep -E "name|script|cwd|PORT"
```

**Kết quả mong đợi:**
- `name: 'asset-rmg-api'` ✅
- `script: './backend/dist/main.js'` ✅
- `cwd: '/var/www/asset-rmg'` ✅
- `PORT: 4001` ✅

---

### 2. Nginx Config

**File**: `/etc/nginx/sites-available/it-request-tracking`

⚠️ **Lưu ý**: File này được dùng chung cho cả 2 app. Cần thêm config của Asset RMG vào file này.

**Kiểm tra config Asset RMG đã được thêm chưa:**
```bash
sudo grep -A 5 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking
```

**Kết quả mong đợi:**
```nginx
    # Asset RMG - Backend API
    location /asset_rmg/api {
        proxy_pass http://localhost:4001;  # ✅ Port 4001
        ...
    }

    # Asset RMG - Frontend
    location /asset_rmg {
        alias /var/www/asset-rmg/frontend/dist;  # ✅ Path đúng
        ...
    }
```

**Nếu chưa có**, thêm vào cuối file (trước dấu `}` cuối cùng):
```bash
sudo nano /etc/nginx/sites-available/it-request-tracking
```

---

### 3. Backend `.env` File

**File**: `/var/www/asset-rmg/backend/.env`

**Kiểm tra:**
```bash
cd /var/www/asset-rmg/backend
cat .env
```

**Nội dung đúng:**
```env
PORT=4001  # ✅ Port 4001 (khác với it-request-tracking)
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars
NODE_ENV=production
```

**Database name**: `asset_rmg_db` ✅ (khác với `it_request_tracking`)

---

### 4. Frontend Build Config

**File**: `/var/www/asset-rmg/frontend/vite.config.ts`

**Kiểm tra:**
```bash
cd /var/www/asset-rmg/frontend
cat vite.config.ts | grep base
```

**Kết quả mong đợi:**
```typescript
base: process.env.NODE_ENV === 'production' ? '/asset_rmg/' : '/'
```

---

## 🔍 So Sánh 2 Ứng Dụng

| Thông Tin | IT Request Tracking | Asset RMG |
|-----------|---------------------|-----------|
| **Project Path** | `/var/www/it-request-tracking` | `/var/www/asset-rmg` ✅ |
| **PM2 Name** | `it-request-tracking-api` | `asset-rmg-api` ✅ |
| **Backend Port** | `4000` | `4001` ✅ |
| **Backend Path** | `/var/www/it-request-tracking/server/dist` | `/var/www/asset-rmg/backend/dist` ✅ |
| **Frontend Path** | `/var/www/it-request-tracking/webapp/dist` | `/var/www/asset-rmg/frontend/dist` ✅ |
| **Nginx Location** | `/` và `/api` | `/asset_rmg` và `/asset_rmg/api` ✅ |
| **Database** | `it_request_tracking` | `asset_rmg_db` ✅ |
| **Database User** | `it_user` | `asset_user` ✅ |

---

## ✅ Checklist Kiểm Tra

Chạy các lệnh sau để kiểm tra:

```bash
# 1. Kiểm tra PM2 config
cd /var/www/asset-rmg
cat ecosystem.config.js | grep -E "name|PORT"

# 2. Kiểm tra backend .env
cd /var/www/asset-rmg/backend
cat .env | grep -E "PORT|DATABASE_URL"

# 3. Kiểm tra Nginx config
sudo grep -A 3 "location /asset_rmg" /etc/nginx/sites-available/it-request-tracking

# 4. Kiểm tra PM2 processes
pm2 list | grep -E "asset-rmg|it-request"

# 5. Kiểm tra ports đang dùng
sudo netstat -tlnp | grep -E "4000|4001"
```

---

## 🚨 Nếu File Config Sai

### Nếu PM2 config sai:
```bash
cd /var/www/asset-rmg
git pull origin main
cat ecosystem.config.js  # Kiểm tra lại
```

### Nếu Nginx config chưa có Asset RMG:
```bash
# Backup file hiện tại
sudo cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup

# Mở file để chỉnh sửa
sudo nano /etc/nginx/sites-available/it-request-tracking

# Thêm config Asset RMG (xem file nginx-asset-rmg.conf trong repo)
# Sau đó test và reload
sudo nginx -t
sudo systemctl reload nginx
```

---

## 📝 Tóm Tắt

- ✅ **PM2 config** (`ecosystem.config.js`) phải ở `/var/www/asset-rmg/` và dùng port **4001**
- ✅ **Nginx config** được thêm vào file `/etc/nginx/sites-available/it-request-tracking` (file chung)
- ✅ **Backend .env** phải có `PORT=4001` và database `asset_rmg_db`
- ✅ **Frontend** build với base path `/asset_rmg/`

Tất cả các file trong repo đều đúng cho Asset RMG. Chỉ cần đảm bảo trên server:
1. Pull code mới nhất
2. Build backend và frontend
3. Thêm Nginx config (nếu chưa có)
4. Start PM2 với `ecosystem.config.js`
