# ⚡ Quick Deploy Guide - Asset RMG

## 📋 Thông tin nhanh

- **Server**: `27.71.16.15`
- **Nginx Config**: `/etc/nginx/sites-available/it-request-tracking`
- **URL**: `http://27.71.16.15/asset_rmg`
- **Backend Port**: `4001`

---

## 🚀 Deploy nhanh (3 bước)

### Bước 1: Push code lên GitHub

```bash
cd d:\IT-LIST-RMG
git add .
git commit -m "Deploy Asset RMG"
git push origin main
```

### Bước 2: SSH vào server và clone/setup

```bash
ssh root@27.71.16.15

# Clone project
cd /var/www
git clone https://github.com/HaiNguyen26/asset_RMG.git asset-rmg
cd asset-rmg

# Chạy script setup tự động
chmod +x server-setup.sh
./server-setup.sh
```

### Bước 3: Thêm Nginx config vào file IT Request Tracking

```bash
# Backup file config
cp /etc/nginx/sites-available/it-request-tracking /etc/nginx/sites-available/it-request-tracking.backup

# Mở file để chỉnh sửa
nano /etc/nginx/sites-available/it-request-tracking
```

**Thêm vào cuối file, trước dấu `}` cuối cùng:**

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
    }

    # Asset RMG - Frontend
    location /asset_rmg {
        alias /var/www/asset-rmg/frontend/dist;
        index index.html;
        try_files $uri $uri/ /asset_rmg/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
```

**Test và reload:**
```bash
nginx -t
systemctl reload nginx
```

---

## ✅ Kiểm tra

```bash
# Kiểm tra PM2
pm2 status

# Kiểm tra backend API
curl http://localhost:4001/health
curl http://27.71.16.15/asset_rmg/api/health

# Kiểm tra logs
pm2 logs asset-rmg-api
```

**Truy cập**: http://27.71.16.15/asset_rmg

---

## 🔄 Update sau này

```bash
ssh root@27.71.16.15
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
tail -f /var/log/nginx/it-request-error.log
```

### Database error
```bash
# Kiểm tra .env
cat /var/www/asset-rmg/backend/.env

# Kiểm tra database
sudo -u postgres psql -d asset_rmg_db -c "SELECT 1;"
```
