#!/bin/bash
# Script tự động fix build issue

set -e

cd /var/www/asset-rmg/backend

echo "🔧 Fixing build issue..."
echo "========================"

# 1. Clean
echo "🧹 Cleaning old build..."
rm -rf dist

# 2. Reinstall dependencies
echo "📦 Reinstalling dependencies..."
npm install

# 3. Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate

# 4. Build với output chi tiết
echo "🏗️  Building backend (detailed output)..."
npm run build 2>&1 | tee /tmp/build.log

# 5. Kiểm tra kết quả
if [ -f dist/main.js ]; then
    echo ""
    echo "✅ Build thành công! File dist/main.js tồn tại"
    ls -lh dist/main.js
    echo ""
    echo "📊 Files trong dist/:"
    ls -la dist/ | head -10
else
    echo ""
    echo "❌ Build thất bại! File dist/main.js không tồn tại"
    echo ""
    echo "📋 Build log (last 50 lines):"
    tail -50 /tmp/build.log
    echo ""
    echo "🔍 Checking dist folder:"
    ls -la dist/ 2>/dev/null || echo "dist folder không tồn tại"
    echo ""
    echo "💡 Thử các bước sau:"
    echo "   1. Xem log chi tiết: cat /tmp/build.log"
    echo "   2. Chạy TypeScript compiler: npx tsc --noEmit"
    echo "   3. Build với verbose: npx nest build --verbose"
    exit 1
fi
