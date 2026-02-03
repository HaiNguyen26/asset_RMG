#!/bin/bash
# Script nhanh để xóa data đã import, chuẩn bị import lại

set -e

echo "🗑️  Xóa Data Đã Import - Chuẩn Bị Import Lại"
echo "==============================================="

cd /var/www/asset-rmg/backend

# Xác nhận
echo ""
echo "⚠️  Bạn sắp xóa data đã import để import lại!"
echo "   - Assets sẽ bị xóa"
echo "   - Users (trừ IT admin) sẽ bị xóa"
echo "   - Departments sẽ bị xóa"
echo "   - Categories sẽ bị xóa"
echo ""
read -p "Nhập 'DELETE' để xác nhận: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Xóa data
echo ""
echo "🗑️  Đang xóa data đã import..."

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

async function deleteForReimport() {
  try {
    console.log('🔧 Đang kết nối database...');
    
    // Xóa theo thứ tự để tránh foreign key constraint
    console.log('');
    console.log('🗑️  Đang xóa Repair History...');
    const repairCount = await prisma.repairHistory.deleteMany({});
    console.log(`   ✅ Đã xóa ${repairCount.count} records`);
    
    console.log('🗑️  Đang xóa Policies...');
    const policyCount = await prisma.policy.deleteMany({});
    console.log(`   ✅ Đã xóa ${policyCount.count} records`);
    
    console.log('🗑️  Đang xóa Assets...');
    const assetCount = await prisma.asset.deleteMany({});
    console.log(`   ✅ Đã xóa ${assetCount.count} assets`);
    
    console.log('🗑️  Đang xóa Users (giữ lại IT admin)...');
    const userCount = await prisma.user.deleteMany({
      where: {
        employeesCode: {
          not: 'IT'
        }
      }
    });
    console.log(`   ✅ Đã xóa ${userCount.count} users (giữ lại IT admin)`);
    
    console.log('🗑️  Đang xóa Departments...');
    const deptCount = await prisma.department.deleteMany({});
    console.log(`   ✅ Đã xóa ${deptCount.count} departments`);
    
    console.log('🗑️  Đang xóa Categories...');
    const catCount = await prisma.category.deleteMany({});
    console.log(`   ✅ Đã xóa ${catCount.count} categories`);
    
    console.log('');
    console.log('========================================');
    console.log('✅ Đã xóa TẤT CẢ data đã import!');
    console.log('========================================');
    console.log('');
    console.log('💡 Bây giờ bạn có thể:');
    console.log('   1. Import lại data từ Excel');
    console.log('   2. Hoặc seed lại data: npx prisma db seed');
    console.log('');
    console.log('📋 Tài khoản IT admin vẫn được giữ lại:');
    console.log('   Mã nhân viên: IT');
    console.log('   Mật khẩu: Hainguyen261097');
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

deleteForReimport();
NODE_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
    echo ""
    echo "💡 Bây giờ bạn có thể import lại data từ Excel"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
