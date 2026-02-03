#!/bin/bash
# Script kiểm tra số lượng data hiện tại

echo "🔍 Kiểm Tra Số Lượng Data"
echo "=========================="

cd /var/www/asset-rmg/backend

# Đảm bảo Prisma Client đã generate
npx prisma generate > /dev/null 2>&1

DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" \
node << 'NODE_SCRIPT'
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

async function checkDataCount() {
  try {
    console.log('🔧 Đang kết nối database...');
    console.log('');
    
    const assets = await prisma.asset.count();
    const users = await prisma.user.count();
    const depts = await prisma.department.count();
    const cats = await prisma.category.count();
    const repairs = await prisma.repairHistory.count();
    const policies = await prisma.policy.count();
    
    console.log('📊 Số lượng data hiện tại:');
    console.log('   Assets: ' + assets);
    console.log('   Users: ' + users);
    console.log('   Departments: ' + depts);
    console.log('   Categories: ' + cats);
    console.log('   Repair History: ' + repairs);
    console.log('   Policies: ' + policies);
    console.log('');
    
    if (assets > 0 || depts > 0 || cats > 0 || repairs > 0 || policies > 0) {
      console.log('⚠️  Vẫn còn data trong database!');
      console.log('');
      console.log('💡 Để xóa data, chạy:');
      console.log('   ./FORCE_DELETE_ALL_DATA.sh');
    } else {
      console.log('✅ Database đã trống (chỉ còn IT admin user)');
    }
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

checkDataCount();
NODE_SCRIPT
