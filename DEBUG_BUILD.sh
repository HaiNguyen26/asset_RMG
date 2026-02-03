#!/bin/bash
# Script để debug build backend

set -e

echo "🔍 Debugging backend build..."

cd /var/www/asset-rmg/backend

# Kiểm tra Node.js version
echo "📌 Node.js version:"
node -v

# Kiểm tra npm version
echo "📌 npm version:"
npm -v

# Kiểm tra file .env
echo "📌 Checking .env file:"
if [ -f .env ]; then
    echo "✅ .env exists"
    # Không hiển thị nội dung để bảo mật
else
    echo "❌ .env không tồn tại"
fi

# Kiểm tra node_modules
echo "📌 Checking node_modules:"
if [ -d node_modules ]; then
    echo "✅ node_modules exists"
    echo "   Checking key dependencies..."
    [ -d node_modules/@nestjs/core ] && echo "   ✅ @nestjs/core" || echo "   ❌ @nestjs/core missing"
    [ -d node_modules/@prisma/client ] && echo "   ✅ @prisma/client" || echo "   ❌ @prisma/client missing"
else
    echo "❌ node_modules không tồn tại - cần chạy npm install"
fi

# Kiểm tra Prisma Client đã generate chưa
echo "📌 Checking Prisma Client:"
if [ -d node_modules/.prisma/client ]; then
    echo "✅ Prisma Client generated"
else
    echo "⚠️  Prisma Client chưa được generate"
    echo "   Running: npx prisma generate"
    npx prisma generate || echo "❌ Prisma generate failed"
fi

# Kiểm tra TypeScript config
echo "📌 Checking TypeScript config:"
[ -f tsconfig.json ] && echo "✅ tsconfig.json exists" || echo "❌ tsconfig.json missing"
[ -f nest-cli.json ] && echo "✅ nest-cli.json exists" || echo "❌ nest-cli.json missing"

# Xóa dist cũ để build sạch
echo "📌 Cleaning old build:"
rm -rf dist
echo "✅ Cleaned dist folder"

# Chạy build với output chi tiết
echo "📌 Building backend (detailed output)..."
echo "----------------------------------------"
npm run build 2>&1 | tee /tmp/build.log
echo "----------------------------------------"

# Kiểm tra kết quả
if [ -f dist/main.js ]; then
    echo "✅ Build thành công! File dist/main.js tồn tại"
    ls -lh dist/main.js
else
    echo "❌ Build thất bại! File dist/main.js không tồn tại"
    echo ""
    echo "📋 Build log (last 50 lines):"
    tail -50 /tmp/build.log || echo "Không có log"
    echo ""
    echo "🔍 Checking dist folder:"
    ls -la dist/ 2>/dev/null || echo "dist folder không tồn tại"
fi
