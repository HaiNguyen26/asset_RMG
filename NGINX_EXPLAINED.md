# 🌐 Nginx là gì và cách hoạt động với các Web Apps

## 📚 Nginx là gì?

**Nginx** (đọc là "engine-x") là một **web server** và **reverse proxy** phổ biến. Nó có nhiệm vụ:

1. **Nhận request từ người dùng** (qua browser)
2. **Chuyển tiếp request** đến ứng dụng phù hợp
3. **Trả về response** cho người dùng

## 🏗️ Kiến Trúc Cơ Bản

```
Người dùng (Browser)
        ↓
    [Nginx] ← Web Server chính
        ↓
    ┌────┴────┐
    ↓         ↓
[App 1]   [App 2]   [App 3]
Port 4000  Port 4001  Port 4002
```

## 🎯 Tại Sao Cần Nginx?

### 1. **Một Server, Nhiều Ứng Dụng**

Thay vì mỗi app phải chạy trên port riêng và người dùng phải nhớ port:
- ❌ `http://27.71.16.15:4000` (IT Request Tracking)
- ❌ `http://27.71.16.15:4001` (Asset RMG)
- ❌ `http://27.71.16.15:4002` (App khác)

Nginx cho phép:
- ✅ `http://27.71.16.15/` → IT Request Tracking
- ✅ `http://27.71.16.15/asset_rmg` → Asset RMG
- ✅ `http://27.71.16.15/app3` → App khác

### 2. **Reverse Proxy**

Nginx nhận request và chuyển tiếp đến ứng dụng backend:

```nginx
location /asset_rmg/api {
    proxy_pass http://localhost:4001;  # Chuyển đến app chạy trên port 4001
}
```

### 3. **Serve Static Files**

Nginx có thể serve file tĩnh (HTML, CSS, JS, images) trực tiếp mà không cần qua backend:

```nginx
location /asset_rmg {
    alias /var/www/asset-rmg/frontend/dist;  # Serve file từ thư mục này
    index index.html;
}
```

## 📝 Cấu Trúc File Nginx Config

### File Config Chính

Trên server Linux, file config thường ở:
- `/etc/nginx/sites-available/` - Các file config có sẵn
- `/etc/nginx/sites-enabled/` - Các file config đang được sử dụng

### Ví Dụ File Config

```nginx
server {
    listen 80;  # Lắng nghe trên port 80 (HTTP)
    server_name 27.71.16.15;  # Domain hoặc IP
    
    # ============================================
    # App 1: IT Request Tracking
    # ============================================
    location / {
        proxy_pass http://localhost:4000;  # Chuyển đến app port 4000
    }
    
    location /api {
        proxy_pass http://localhost:4000/api;
    }
    
    # ============================================
    # App 2: Asset RMG
    # ============================================
    location /asset_rmg/api {
        proxy_pass http://localhost:4001;  # Chuyển đến app port 4001
    }
    
    location /asset_rmg {
        alias /var/www/asset-rmg/frontend/dist;  # Serve static files
        index index.html;
    }
    
    # ============================================
    # App 3: App khác
    # ============================================
    location /app3 {
        proxy_pass http://localhost:4002;  # Chuyển đến app port 4002
    }
}
```

## ✅ Câu Trả Lời Cho Câu Hỏi Của Bạn

### "Nginx này là để chạy các ứng dụng đúng không?"

**Đúng!** Nginx là web server chính để:
- Nhận tất cả request từ internet
- Phân phối request đến ứng dụng phù hợp
- Serve static files (HTML, CSS, JS, images)

### "Web nào tạo ra muốn chạy phải thêm vào Nginx này đúng không?"

**Đúng!** Mỗi web app mới cần:

1. **Chạy backend** trên một port riêng (ví dụ: 4001, 4002, ...)
2. **Thêm config vào Nginx** để:
   - Nhận request từ URL cụ thể (ví dụ: `/asset_rmg`)
   - Chuyển tiếp đến backend app (port 4001)
   - Serve frontend static files (nếu có)

## 🔄 Quy Trình Thêm App Mới

### Bước 1: Chạy Backend App

```bash
# App chạy trên port 4001
cd /var/www/asset-rmg/backend
npm run build
pm2 start ecosystem.config.js
```

### Bước 2: Build Frontend (nếu có)

```bash
cd /var/www/asset-rmg/frontend
npm run build
```

### Bước 3: Thêm Config Vào Nginx

```bash
sudo nano /etc/nginx/sites-available/it-request-tracking
```

Thêm vào file:

```nginx
# App mới - Backend API
location /app_name/api {
    proxy_pass http://localhost:PORT_NUMBER;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

# App mới - Frontend
location /app_name {
    alias /var/www/app-name/frontend/dist;
    index index.html;
    try_files $uri $uri/ /app_name/index.html;
}
```

### Bước 4: Test và Reload Nginx

```bash
sudo nginx -t        # Test config
sudo systemctl reload nginx  # Reload để áp dụng
```

## 📊 Ví Dụ Thực Tế

### Server hiện tại có:

1. **IT Request Tracking**
   - Backend: Port 4000
   - Nginx: `location /` → `http://localhost:4000`
   - URL: `http://27.71.16.15/`

2. **Asset RMG** (mới thêm)
   - Backend: Port 4001
   - Nginx: `location /asset_rmg/api` → `http://localhost:4001`
   - Frontend: `location /asset_rmg` → `/var/www/asset-rmg/frontend/dist`
   - URL: `http://27.71.16.15/asset_rmg`

### Nếu thêm App thứ 3:

```nginx
# App 3 - Backend
location /app3/api {
    proxy_pass http://localhost:4002;
}

# App 3 - Frontend
location /app3 {
    alias /var/www/app3/frontend/dist;
    index index.html;
}
```

## 🎯 Tóm Tắt

- ✅ **Nginx = Web Server chính** để nhận tất cả request
- ✅ **Mỗi app chạy trên port riêng** (4000, 4001, 4002, ...)
- ✅ **Mỗi app cần thêm config vào Nginx** để có URL riêng
- ✅ **Nginx phân phối request** đến app phù hợp dựa trên URL path
- ✅ **Một server có thể chạy nhiều apps** thông qua Nginx

## 💡 Lợi Ích

1. **Một domain/IP cho nhiều apps**
2. **URL thân thiện** (không cần nhớ port)
3. **Dễ quản lý** (tất cả config ở một nơi)
4. **Hiệu suất tốt** (Nginx xử lý static files nhanh)
5. **Bảo mật** (có thể thêm SSL, rate limiting, ...)
