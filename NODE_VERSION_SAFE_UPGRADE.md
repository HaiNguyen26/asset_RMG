# 🔒 Upgrade Node.js An Toàn - Không Ảnh Hưởng App Khác

## ⚠️ Vấn đề

Trên server đang có:
- **IT Request Tracking** app chạy với Node.js v18.20.8
- **Asset RMG** cần Node.js >= 20.19

Nếu upgrade Node.js global, có thể ảnh hưởng đến IT Request app.

---

## ✅ Giải pháp AN TOÀN: Dùng NVM (Node Version Manager)

NVM cho phép chạy nhiều version Node.js khác nhau cho từng project.

### Cách 1: Dùng NVM (Khuyến nghị - An toàn nhất)

#### 1.1. Cài đặt NVM

```bash
# Cài đặt NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# Load NVM vào shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Thêm vào ~/.bashrc để tự động load
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
source ~/.bashrc
```

#### 1.2. Cài đặt Node.js 20 cho Asset RMG

```bash
# Cài đặt Node.js 20 LTS
nvm install 20
nvm use 20

# Kiểm tra
node --version
# Phải >= v20.19.0
```

#### 1.3. Setup Asset RMG với Node.js 20

```bash
cd /var/www/asset-rmg/backend

# Đảm bảo đang dùng Node.js 20
nvm use 20
node --version

# Cài đặt dependencies
rm -rf node_modules package-lock.json
npm install
```

#### 1.4. Cấu hình PM2 để dùng Node.js 20

```bash
cd /var/www/asset-rmg

# Tìm đường dẫn Node.js 20
which node
# Ví dụ: /root/.nvm/versions/node/v20.18.0/bin/node

# Chỉnh sửa ecosystem.config.js
nano ecosystem.config.js
```

**Cập nhật ecosystem.config.js:**
```javascript
module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',
      script: './backend/dist/main.js',
      cwd: '/var/www/asset-rmg',
      interpreter: '/root/.nvm/versions/node/v20.18.0/bin/node', // Thay bằng path thực tế
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 4001,
      },
      error_file: '/var/log/pm2/asset-rmg-error.log',
      out_file: '/var/log/pm2/asset-rmg-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
}
```

**Hoặc đơn giản hơn, dùng nvm trong PM2:**

```bash
# Start với nvm
cd /var/www/asset-rmg
source ~/.nvm/nvm.sh && nvm use 20 && pm2 start ecosystem.config.js
```

---

## ✅ Cách 2: Upgrade Global nhưng Test IT Request App

### 2.1. Backup và Test

```bash
# Kiểm tra IT Request app đang chạy
pm2 list
pm2 logs it-request-api

# Backup Node.js version hiện tại (nếu có thể)
which node
cp $(which node) /usr/local/bin/node.backup
```

### 2.2. Upgrade Node.js Global

```bash
# Upgrade Node.js lên 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Kiểm tra
node --version
```

### 2.3. Test IT Request App

```bash
# Restart IT Request app
pm2 restart it-request-api

# Kiểm tra logs
pm2 logs it-request-api --lines 50

# Test API
curl http://localhost:4000/health
curl http://27.71.16.15/api/health
```

**Nếu IT Request app vẫn chạy OK**: ✅ Không có vấn đề  
**Nếu IT Request app bị lỗi**: ⚠️ Cần rollback hoặc fix

### 2.4. Rollback nếu cần (nếu IT Request bị lỗi)

```bash
# Xóa Node.js 20
apt-get remove -y nodejs

# Cài lại Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Restart IT Request
pm2 restart it-request-api
```

---

## ✅ Cách 3: Dùng Docker (Nâng cao)

Nếu muốn hoàn toàn tách biệt, có thể dùng Docker cho từng app, nhưng phức tạp hơn.

---

## 🎯 Khuyến nghị

### Option A: Dùng NVM (An toàn nhất) ⭐

**Ưu điểm:**
- ✅ Không ảnh hưởng IT Request app
- ✅ Có thể chạy nhiều version Node.js
- ✅ Dễ quản lý

**Nhược điểm:**
- ⚠️ Cần cấu hình PM2 với interpreter path

### Option B: Upgrade Global và Test

**Ưu điểm:**
- ✅ Đơn giản hơn
- ✅ PM2 tự động dùng Node.js mới

**Nhược điểm:**
- ⚠️ Có thể ảnh hưởng IT Request app
- ⚠️ Cần test kỹ

---

## 📝 Checklist

### Nếu dùng NVM:
- [ ] NVM đã được cài đặt
- [ ] Node.js 20 đã được cài qua NVM
- [ ] PM2 ecosystem.config.js đã chỉnh với interpreter path
- [ ] Asset RMG backend chạy OK với Node.js 20
- [ ] IT Request app vẫn chạy OK với Node.js 18 (qua PM2)

### Nếu upgrade Global:
- [ ] Đã backup Node.js cũ
- [ ] Node.js 20 đã được cài
- [ ] IT Request app đã được test và vẫn chạy OK
- [ ] Asset RMG backend chạy OK
- [ ] Cả 2 apps đều hoạt động bình thường

---

## 🔍 Kiểm tra sau khi upgrade

```bash
# Kiểm tra Node.js version
node --version

# Kiểm tra PM2 processes
pm2 list

# Kiểm tra IT Request app
pm2 logs it-request-api --lines 20
curl http://localhost:4000/health

# Kiểm tra Asset RMG app
pm2 logs asset-rmg-api --lines 20
curl http://localhost:4001/health
```

---

## 💡 Lời khuyên

**Nếu bạn muốn an toàn 100%**: Dùng **NVM (Cách 1)**  
**Nếu bạn muốn đơn giản**: Dùng **Upgrade Global (Cách 2)** và test kỹ IT Request app

Nếu IT Request app không có dependencies đặc biệt yêu cầu Node.js 18, thì upgrade lên 20 thường không có vấn đề.
