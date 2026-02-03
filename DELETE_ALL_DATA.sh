#!/bin/bash
# Script xóa TẤT CẢ data trên server (không hỏi)

set -e

echo "🗑️  Xóa TẤT CẢ Data trên Server"
echo "================================"

cd /var/www/asset-rmg/backend

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Xác nhận
echo ""
echo "⚠️  CẢNH BÁO: Bạn sắp xóa TẤT CẢ data trong database!"
echo "   Điều này không thể hoàn tác!"
echo ""
read -p "Nhập 'DELETE ALL' để xác nhận: " confirm

if [ "$confirm" != "DELETE ALL" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

# Chạy script Node.js để xóa tất cả data
echo ""
echo "🗑️  Đang xóa TẤT CẢ data..."

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

async function deleteAllData() {
  try {
    console.log('🔧 Đang kết nối database...');
    
    console.log('🗑️  Đang xóa Repair History...');
    const repairCount = await prisma.repairHistory.deleteMany({});
    console.log(`   ✅ Đã xóa ${repairCount.count} records`);
    
    console.log('🗑️  Đang xóa Policies...');
    const policyCount = await prisma.policy.deleteMany({});
    console.log(`   ✅ Đã xóa ${policyCount.count} records`);
    
    console.log('🗑️  Đang xóa Assets...');
    const assetCount = await prisma.asset.deleteMany({});
    console.log(`   ✅ Đã xóa ${assetCount.count} records`);
    
    console.log('🗑️  Đang xóa Users...');
    const userCount = await prisma.user.deleteMany({});
    console.log(`   ✅ Đã xóa ${userCount.count} records`);
    
    console.log('🗑️  Đang xóa Departments...');
    const deptCount = await prisma.department.deleteMany({});
    console.log(`   ✅ Đã xóa ${deptCount.count} records`);
    
    console.log('🗑️  Đang xóa Categories...');
    const catCount = await prisma.category.deleteMany({});
    console.log(`   ✅ Đã xóa ${catCount.count} records`);
    
    console.log('');
    console.log('========================================');
    console.log('✅ Đã xóa TẤT CẢ data thành công!');
    console.log('========================================');
    console.log('');
    console.log('💡 Để seed lại data, chạy:');
    console.log('   cd /var/www/asset-rmg/backend');
    console.log('   npx prisma db seed');
  } catch (error) {
    console.error('❌ Lỗi:', error.message);
    if (error.code) {
      console.error('   Error code:', error.code);
    }
    console.error('');
    console.error('Stack trace:');
    console.error(error.stack);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

deleteAllData();
NODE_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
