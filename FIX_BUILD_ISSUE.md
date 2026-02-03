# 🔧 Fix Build Issue - dist/main.js không tồn tại

## 🚨 Vấn Đề

Build báo thành công nhưng file `dist/main.js` không tồn tại.

## 🔍 Nguyên Nhân Có Thể

1. **TypeScript compilation errors** - Có lỗi TypeScript nhưng không hiển thị
2. **NestJS build config sai** - Cấu hình build không đúng
3. **Missing dependencies** - Thiếu dependencies cần thiết
4. **Build output path sai** - File được build ra nơi khác

## ✅ Cách Khắc Phục

### Bước 1: Xem Log Chi Tiết Của Build

```bash
cd /var/www/asset-rmg/backend

# Build với output chi tiết
npm run build 2>&1 | tee build.log

# Xem log
cat build.log
```

### Bước 2: Kiểm Tra TypeScript Errors

```bash
cd /var/www/asset-rmg/backend

# Chạy TypeScript compiler trực tiếp để xem lỗi
npx tsc --noEmit

# Hoặc build với verbose
npx nest build --verbose
```

### Bước 3: Kiểm Tra Cấu Hình

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra tsconfig.json
cat tsconfig.json | grep -E "outDir|rootDir"

# Kiểm tra nest-cli.json
cat nest-cli.json

# Kiểm tra package.json build script
cat package.json | grep -A 2 "build"
```

### Bước 4: Clean và Build Lại

```bash
cd /var/www/asset-rmg/backend

# Xóa dist cũ
rm -rf dist

# Xóa node_modules và reinstall (nếu cần)
# rm -rf node_modules
# npm install

# Generate Prisma Client lại
npx prisma generate

# Build lại
npm run build

# Kiểm tra file
ls -la dist/
ls -la dist/main.js
```

### Bước 5: Build Thủ Công Với NestJS CLI

```bash
cd /var/www/asset-rmg/backend

# Build với NestJS CLI trực tiếp
npx nest build

# Hoặc với verbose
npx nest build --verbose

# Kiểm tra output
ls -la dist/
```

### Bước 6: Kiểm Tra Dependencies

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra NestJS CLI có cài không
npx nest --version

# Nếu không có, cài lại
npm install --save-dev @nestjs/cli

# Kiểm tra TypeScript
npx tsc --version
```

## 🔍 Debug Chi Tiết

### Xem Tất Cả Files Trong Dist

```bash
cd /var/www/asset-rmg/backend

# Build
npm run build

# Xem tất cả files trong dist
find dist -type f

# Xem cấu trúc thư mục
tree dist/ || find dist -type d
```

### Kiểm Tra Main Entry Point

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra file main.ts có tồn tại không
ls -la src/main.ts

# Kiểm tra nội dung
head -20 src/main.ts
```

### Test Compile TypeScript Thủ Công

```bash
cd /var/www/asset-rmg/backend

# Compile TypeScript thủ công
npx tsc

# Xem output
ls -la dist/
```

## 🚨 Nếu Vẫn Không Được

### Kiểm Tra Node.js Version

```bash
node -v
# Cần >= 20.19 cho Prisma, nhưng có thể cần version khác cho NestJS
```

### Reinstall Dependencies

```bash
cd /var/www/asset-rmg/backend

# Xóa node_modules và package-lock.json
rm -rf node_modules package-lock.json

# Reinstall
npm install

# Generate Prisma lại
npx prisma generate

# Build lại
npm run build
```

### Kiểm Tra Permissions

```bash
cd /var/www/asset-rmg/backend

# Kiểm tra permissions
ls -la

# Set permissions nếu cần
chmod -R 755 .
```

## 📝 Script Tự Động Fix

Tạo file `fix-build.sh`:

```bash
#!/bin/bash
cd /var/www/asset-rmg/backend

echo "🧹 Cleaning..."
rm -rf dist

echo "📦 Reinstalling dependencies..."
npm install

echo "🔧 Generating Prisma Client..."
npx prisma generate

echo "🏗️  Building..."
npm run build 2>&1 | tee build.log

if [ -f dist/main.js ]; then
    echo "✅ Build thành công! File dist/main.js tồn tại"
    ls -lh dist/main.js
else
    echo "❌ Build thất bại! Xem build.log để biết lỗi"
    echo "📋 Last 50 lines of build.log:"
    tail -50 build.log
fi
```

## 💡 Quick Fix Command

```bash
cd /var/www/asset-rmg/backend && \
rm -rf dist && \
npm install && \
npx prisma generate && \
npm run build && \
ls -la dist/main.js
```
