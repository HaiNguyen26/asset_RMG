#!/bin/bash
# Script xóa TẤT CẢ data một cách mạnh mẽ

set -e

echo "🗑️  Force Delete TẤT CẢ Data"
echo "=============================="

cd /var/www/asset-rmg/backend

# Xác nhận
echo ""
echo "⚠️  ⚠️  ⚠️  CẢNH BÁO NGHIÊM TRỌNG ⚠️  ⚠️  ⚠️"
echo "   Bạn sắp xóa TẤT CẢ data trong database!"
echo "   Điều này không thể hoàn tác!"
echo ""
read -p "Nhập 'DELETE ALL DATA' để xác nhận: " confirm

if [ "$confirm" != "DELETE ALL DATA" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Xóa data với nhiều cách để đảm bảo
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

async function forceDeleteAll() {
  try {
    console.log('🔧 Đang kết nối database...');
    
    // Xóa theo thứ tự để tránh foreign key constraint
    console.log('');
    console.log('🗑️  Bước 1: Xóa Repair History...');
    try {
      const repairCount = await prisma.repairHistory.deleteMany({});
      console.log(`   ✅ Đã xóa ${repairCount.count} repair history records`);
    } catch (e) {
      console.log(`   ⚠️  Lỗi: ${e.message}`);
    }
    
    console.log('🗑️  Bước 2: Xóa Policies...');
    try {
      const policyCount = await prisma.policy.deleteMany({});
      console.log(`   ✅ Đã xóa ${policyCount.count} policies`);
    } catch (e) {
      console.log(`   ⚠️  Lỗi: ${e.message}`);
    }
    
    console.log('🗑️  Bước 3: Xóa Assets...');
    try {
      const assetCount = await prisma.asset.deleteMany({});
      console.log(`   ✅ Đã xóa ${assetCount.count} assets`);
    } catch (e) {
      console.log(`   ⚠️  Lỗi: ${e.message}`);
    }
    
    console.log('🗑️  Bước 4: Xóa Users (giữ lại IT admin)...');
    try {
      const userCount = await prisma.user.deleteMany({
        where: {
          employeesCode: {
            not: 'IT'
          }
        }
      });
      console.log(`   ✅ Đã xóa ${userCount.count} users (giữ lại IT admin)`);
    } catch (e) {
      console.log(`   ⚠️  Lỗi: ${e.message}`);
    }
    
    console.log('🗑️  Bước 5: Xóa Departments...');
    try {
      const deptCount = await prisma.department.deleteMany({});
      console.log(`   ✅ Đã xóa ${deptCount.count} departments`);
    } catch (e) {
      console.log(`   ⚠️  Lỗi: ${e.message}`);
    }
    
    console.log('🗑️  Bước 6: Xóa Categories...');
    try {
      const catCount = await prisma.category.deleteMany({});
      console.log(`   ✅ Đã xóa ${catCount.count} categories`);
    } catch (e) {
      console.log(`   ⚠️  Lỗi: ${e.message}`);
    }
    
    // Kiểm tra lại
    console.log('');
    console.log('🔍 Kiểm tra lại số lượng records...');
    const assets = await prisma.asset.count();
    const users = await prisma.user.count();
    const depts = await prisma.department.count();
    const cats = await prisma.category.count();
    const repairs = await prisma.repairHistory.count();
    const policies = await prisma.policy.count();
    
    console.log(`   Assets: ${assets}`);
    console.log(`   Users: ${users}`);
    console.log(`   Departments: ${depts}`);
    console.log(`   Categories: ${cats}`);
    console.log(`   Repair History: ${repairs}`);
    console.log(`   Policies: ${policies}`);
    
    if (assets === 0 && depts === 0 && cats === 0 && repairs === 0 && policies === 0) {
      console.log('');
      console.log('✅ TẤT CẢ data đã được xóa thành công!');
    } else {
      console.log('');
      console.log('⚠️  Vẫn còn một số data!');
      console.log('   Có thể do foreign key constraints');
      console.log('   Thử xóa lại hoặc kiểm tra database trực tiếp');
    }
    
    console.log('');
    console.log('========================================');
    console.log('✅ Hoàn thành!');
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

forceDeleteAll();
NODE_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Script đã chạy xong!"
    echo ""
    echo "💡 Refresh lại browser để xem kết quả"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
