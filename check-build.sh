#!/bin/bash
# Script kiểm tra và debug build issue

cd /var/www/asset-rmg/backend

echo "🔍 Kiểm tra build issue..."
echo "=========================="

# 1. Kiểm tra file main.ts có tồn tại không
echo ""
echo "1️⃣  Kiểm tra file main.ts:"
if [ -f src/main.ts ]; then
    echo "✅ File src/main.ts tồn tại"
    ls -lh src/main.ts
else
    echo "❌ File src/main.ts KHÔNG tồn tại!"
    exit 1
fi

# 2. Kiểm tra dist folder
echo ""
echo "2️⃣  Kiểm tra thư mục dist:"
if [ -d dist ]; then
    echo "✅ Thư mục dist tồn tại"
    echo "📁 Files trong dist:"
    ls -la dist/ | head -20
    echo ""
    echo "🔍 Tìm file main.js:"
    find dist -name "main.js" -type f 2>/dev/null || echo "❌ Không tìm thấy main.js"
    echo ""
    echo "🔍 Tìm tất cả .js files:"
    find dist -name "*.js" -type f 2>/dev/null | head -10 || echo "❌ Không có file .js nào"
else
    echo "❌ Thư mục dist KHÔNG tồn tại!"
fi

# 3. Kiểm tra TypeScript config
echo ""
echo "3️⃣  Kiểm tra TypeScript config:"
if [ -f tsconfig.json ]; then
    echo "✅ tsconfig.json tồn tại"
    echo "📋 outDir:"
    grep -E "outDir" tsconfig.json || echo "⚠️  Không tìm thấy outDir"
else
    echo "❌ tsconfig.json KHÔNG tồn tại!"
fi

# 4. Kiểm tra NestJS CLI
echo ""
echo "4️⃣  Kiểm tra NestJS CLI:"
if command -v nest &> /dev/null || npx nest --version &> /dev/null; then
    echo "✅ NestJS CLI có sẵn"
    npx nest --version 2>/dev/null || echo "⚠️  Không thể chạy nest --version"
else
    echo "❌ NestJS CLI KHÔNG có sẵn!"
fi

# 5. Kiểm tra dependencies
echo ""
echo "5️⃣  Kiểm tra dependencies:"
if [ -d node_modules/@nestjs/cli ]; then
    echo "✅ @nestjs/cli đã cài"
else
    echo "❌ @nestjs/cli CHƯA cài!"
fi

if [ -d node_modules/typescript ]; then
    echo "✅ typescript đã cài"
else
    echo "❌ typescript CHƯA cài!"
fi

# 6. Chạy TypeScript compiler để xem lỗi
echo ""
echo "6️⃣  Chạy TypeScript compiler (dry run):"
npx tsc --noEmit 2>&1 | head -30 || echo "⚠️  Có lỗi TypeScript"

# 7. Thử build với verbose
echo ""
echo "7️⃣  Thử build với verbose mode:"
echo "📋 Chạy: npm run build"
npm run build 2>&1 | tail -50

# 8. Kiểm tra lại sau build
echo ""
echo "8️⃣  Kiểm tra lại sau build:"
if [ -f dist/main.js ]; then
    echo "✅ File dist/main.js TỒN TẠI!"
    ls -lh dist/main.js
else
    echo "❌ File dist/main.js VẪN KHÔNG TỒN TẠI!"
    echo ""
    echo "📁 Tất cả files trong dist:"
    ls -la dist/ 2>/dev/null || echo "dist folder không tồn tại"
fi
