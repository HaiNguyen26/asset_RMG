#!/bin/bash
# Script xóa TẤT CẢ seed data (departments, categories, users, assets)

cd /var/www/asset-rmg/backend

echo "🗑️  Xóa TẤT CẢ seed data từ database..."
echo "=========================================="

# Kiểm tra .env
if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    exit 1
fi

echo ""
echo "⚠️  CẢNH BÁO: Script này sẽ xóa:"
echo "   - Tất cả Departments"
echo "   - Tất cả Categories"
echo "   - Tất cả Users (trừ IT Admin nếu bạn muốn giữ)"
echo "   - Tất cả Assets"
echo ""
echo "⚠️  Bạn có chắc muốn tiếp tục? (y/n)"
read -r response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "❌ Hủy bỏ. Không xóa gì."
    exit 0
fi

echo ""
echo "🗑️  Đang xóa seed data..."

node -e "
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function deleteAllSeedData() {
  try {
    console.log('🗑️  Đang xóa...');
    
    // Xóa theo thứ tự để tránh foreign key constraint
    // 1. Xóa Assets trước (vì có foreign key đến categories và departments)
    const assetsResult = await prisma.asset.deleteMany({});
    console.log('✅ Đã xóa', assetsResult.count, 'assets');
    
    // 2. Xóa Users (trừ IT Admin nếu muốn giữ)
    const usersResult = await prisma.user.deleteMany({
      where: {
        employeesCode: { not: 'IT' } // Giữ IT Admin
      }
    });
    console.log('✅ Đã xóa', usersResult.count, 'users (giữ IT Admin)');
    
    // 3. Xóa Departments
    const deptResult = await prisma.department.deleteMany({});
    console.log('✅ Đã xóa', deptResult.count, 'departments');
    
    // 4. Xóa Categories
    const catResult = await prisma.assetCategory.deleteMany({});
    console.log('✅ Đã xóa', catResult.count, 'categories');
    
    console.log('');
    console.log('✅ Hoàn thành! Tất cả seed data đã được xóa.');
    console.log('💡 IT Admin user vẫn được giữ lại.');
    
    await prisma.\$disconnect();
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    await prisma.\$disconnect();
    await pool.end();
    process.exit(1);
  }
}

deleteAllSeedData();
"

echo ""
echo "📋 Kiểm tra lại:"
echo ""
echo "Departments:"
curl -s http://localhost:4001/api/departments || echo "[]"

echo ""
echo "Categories:"
curl -s http://localhost:4001/api/categories || echo "[]"

echo ""
echo "Assets:"
curl -s http://localhost:4001/api/assets || echo "[]"

echo ""
echo "✅ Hoàn thành!"
