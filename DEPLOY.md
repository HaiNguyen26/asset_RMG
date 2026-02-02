# 🚀 Hướng dẫn Deploy Asset RMG lên Server

## 📋 Thông tin Server

- **Server IP**: `27.71.16.15`
- **User**: `root`
- **Path trên server**: `/var/www/asset-rmg`
- **URL truy cập**: `http://27.71.16.15/asset_rmg`
- **Backend Port**: `4001` (tránh conflict với IT Request port 4000)
- **GitHub Repo**: `https://github.com/HaiNguyen26/asset_RMG.git`

---

## 🔧 Bước 1: Chuẩn bị Local

### 1.1. Kiểm tra Git
```bash
git status
```

### 1.2. Commit và Push code
```bash
git add .
git commit -m "Initial deployment"
git remote add origin https://github.com/HaiNguyen26/asset_RMG.git
git push -u origin main
```

---

## 🖥️ Bước 2: Setup trên Server

### 2.1. SSH vào server
```bash
ssh root@27.71.16.15
```

### 2.2. Cài đặt Node.js (nếu chưa có)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
node --version
npm --version
```

### 2.3. Cài đặt PM2 (nếu chưa có)
```bash
npm install -g pm2
pm2 startup
```

### 2.4. Cài đặt PostgreSQL (nếu chưa có)
```bash
apt-get update
apt-get install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql
```

### 2.5. Tạo Database
```bash
sudo -u postgres psql << EOF
CREATE DATABASE asset_rmg_db;
CREATE USER asset_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;
\q
EOF
```

---

## 📥 Bước 3: Clone và Setup Project

### 3.1. Clone repository
```bash
cd /var/www
git clone https://github.com/HaiNguyen26/asset_RMG.git asset-rmg
cd asset-rmg
```

### 3.2. Setup Backend
```bash
cd backend
npm install
cp .env.example .env  # Tạo file .env từ .env.example
nano .env  # Chỉnh sửa các biến môi trường
```

**File `.env` mẫu:**
```env
PORT=4001
DATABASE_URL=postgresql://asset_user:your_secure_password@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production
NODE_ENV=production
```

### 3.3. Setup Database
```bash
cd backend
npx prisma generate
npx prisma migrate deploy
npx prisma db seed  # Nếu cần seed data
```

### 3.4. Build Backend
```bash
npm run build
```

### 3.5. Setup Frontend
```bash
cd ../frontend
npm install
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

---

## ⚙️ Bước 4: Cấu hình PM2

### 4.1. Copy ecosystem config
```bash
cd /var/www/asset-rmg
cp ecosystem.config.js /var/www/asset-rmg/ecosystem.config.js
```

### 4.2. Start với PM2
```bash
cd /var/www/asset-rmg
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Thiết lập auto-start khi reboot
```

### 4.3. Kiểm tra PM2
```bash
pm2 status
pm2 logs asset-rmg-api
```

---

## 🌐 Bước 5: Cấu hình Nginx

### 5.1. Mở file Nginx config của IT Request Tracking

File config đang sử dụng là: `/etc/nginx/sites-enabled/it-request-tracking`

```bash
# Xem file config hiện tại
cat /etc/nginx/sites-enabled/it-request-tracking

# Hoặc mở để chỉnh sửa
nano /etc/nginx/sites-enabled/it-request-tracking
# hoặc
nano /etc/nginx/sites-available/it-request-tracking
```

**Lưu ý**: File trong `sites-enabled` thường là symlink đến file trong `sites-available`. Nên chỉnh sửa file trong `sites-available` để đảm bảo.

### 5.2. Thêm cấu hình vào file Nginx hiện có

Mở file config:
```bash
nano /etc/nginx/sites-available/it-request-tracking
```

**Thêm các location blocks sau vào trong block `server { ... }`:**

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

**Ví dụ file config hoàn chỉnh (`/etc/nginx/sites-available/it-request-tracking`):**
```nginx
server {
    listen 80;
    server_name 27.71.16.15;
    
    # IT Request Tracking (app hiện có)
    root /var/www/it-request-tracking/webapp/dist;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # ============================================
    # Asset RMG - THÊM CÁC BLOCKS SAU ĐÂY
    # ============================================
    
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
}
```

### 5.3. Test và reload Nginx

```bash
# Test cấu hình (quan trọng!)
nginx -t

# Nếu test thành công, reload Nginx
systemctl reload nginx

# Kiểm tra status
systemctl status nginx
```

**⚠️ Lưu ý quan trọng:**
- **KHÔNG** tạo file config mới nếu đã có app khác chạy
- **CHỈ** thêm location blocks vào file config hiện có
- Luôn chạy `nginx -t` trước khi reload để tránh lỗi
- Backup file config trước khi chỉnh sửa: `cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup`

---

## 🔄 Bước 6: Update Frontend Base Path

### 6.1. Cập nhật vite.config.ts
Đảm bảo file `frontend/vite.config.ts` có base path:
```typescript
export default defineConfig({
  base: '/asset_rmg/',
  // ... other config
})
```

### 6.2. Rebuild frontend
```bash
cd /var/www/asset-rmg/frontend
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
```

---

## ✅ Bước 7: Kiểm tra

### 7.1. Kiểm tra Backend API
```bash
curl http://localhost:4001/health
curl http://27.71.16.15/asset_rmg/api/health
```

### 7.2. Kiểm tra Frontend
Mở browser: `http://27.71.16.15/asset_rmg`

### 7.3. Kiểm tra Logs
```bash
pm2 logs asset-rmg-api
tail -f /var/log/nginx/error.log
```

---

## 🔄 Deploy Updates

### Cách 1: Dùng script tự động
```bash
# Từ local machine
./deploy.sh
```

### Cách 2: Deploy thủ công
```bash
# Trên server
cd /var/www/asset-rmg
git pull origin main

# Backend
cd backend
npm install --production
npm run build
pm2 restart asset-rmg-api

# Frontend
cd ../frontend
npm install --production
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

# Reload Nginx
systemctl reload nginx
```

---

## 🐛 Troubleshooting

### Backend không chạy
```bash
pm2 logs asset-rmg-api --lines 50
pm2 restart asset-rmg-api
```

### Frontend không load
```bash
# Kiểm tra build
ls -la /var/www/asset-rmg/frontend/dist/

# Kiểm tra Nginx
nginx -t
tail -f /var/log/nginx/error.log
```

### Database connection error
```bash
# Kiểm tra PostgreSQL
systemctl status postgresql
sudo -u postgres psql -d asset_rmg_db -c "SELECT 1;"

# Kiểm tra .env
cat /var/www/asset-rmg/backend/.env
```

### Port đã được sử dụng
```bash
# Kiểm tra port
netstat -tulpn | grep 4001

# Đổi port trong .env và ecosystem.config.js
```

---

## 📝 Notes

- **Backend Port**: 4001 (tránh conflict với IT Request port 4000)
- **Database**: `asset_rmg_db`
- **PM2 Name**: `asset-rmg-api`
- **Frontend Base**: `/asset_rmg`
- **API Base**: `/asset_rmg/api`

---

## 🔐 Security

- Đổi password database trong production
- Đổi JWT_SECRET trong production
- Cấu hình firewall nếu cần
- Cân nhắc SSL/HTTPS cho production

---

**Last Updated**: 2026-02-02
