# 🔧 Fix Node.js Version Issue

## ❌ Lỗi hiện tại

```
Prisma only supports Node.js versions 20.19+, 22.12+, 24.0+.
Current Node.js version: v18.20.8
```

## ✅ Giải pháp: Upgrade Node.js

### Cách 1: Dùng NodeSource (Khuyến nghị)

```bash
# SSH vào server
ssh root@27.71.16.15

# Xóa Node.js cũ (nếu cần)
apt-get remove -y nodejs npm

# Cài đặt Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Kiểm tra version
node --version
npm --version
```

**Kết quả mong đợi:**
- `node --version`: v20.x.x (ví dụ: v20.18.0)
- `npm --version`: v10.x.x hoặc cao hơn

### Cách 2: Dùng nvm (Node Version Manager)

```bash
# Cài đặt nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Cài đặt Node.js 20 LTS
nvm install 20
nvm use 20
nvm alias default 20

# Kiểm tra
node --version
npm --version
```

### Cách 3: Dùng snap (nếu có)

```bash
snap install node --classic --channel=20
node --version
```

---

## 🔄 Sau khi upgrade Node.js

### 1. Xóa node_modules và package-lock.json cũ

```bash
cd /var/www/asset-rmg/backend
rm -rf node_modules package-lock.json
```

### 2. Cài đặt lại dependencies

```bash
npm install
```

### 3. Tiếp tục các bước setup

```bash
# Generate Prisma
npx prisma generate

# Migrate database
npx prisma migrate deploy

# Build backend
npm run build
```

---

## ✅ Kiểm tra

```bash
# Kiểm tra Node.js version
node --version
# Phải >= 20.19

# Kiểm tra npm version
npm --version

# Test Prisma
cd /var/www/asset-rmg/backend
npx prisma --version
```

---

## 🐛 Nếu vẫn gặp lỗi

### Clear npm cache

```bash
npm cache clean --force
```

### Xóa và cài lại hoàn toàn

```bash
cd /var/www/asset-rmg/backend
rm -rf node_modules package-lock.json
npm install
```

---

## 📝 Lưu ý

- **Node.js 20.x LTS** là version ổn định nhất hiện tại
- Sau khi upgrade, cần rebuild lại backend
- PM2 sẽ tự động detect Node.js version mới khi restart
