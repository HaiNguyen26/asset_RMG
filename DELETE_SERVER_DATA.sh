#!/bin/bash
# Script xóa data trên server

set -e

echo "🗑️  Xóa Data trên Server"
echo "========================="

cd /var/www/asset-rmg/backend

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Hiển thị menu
echo ""
echo "Chọn loại data muốn xóa:"
echo "  1) Xóa tất cả data (tất cả bảng)"
echo "  2) Xóa Users (giữ lại departments, categories)"
echo "  3) Xóa Assets"
echo "  4) Xóa Departments"
echo "  5) Xóa Categories"
echo "  6) Xóa Repair History"
echo "  7) Xóa Policies"
echo "  8) Xóa tất cả và reset về trạng thái ban đầu"
echo ""
read -p "Chọn (1-8): " choice

# Chạy script Node.js để xóa data
DATABASE_URL="postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db" \
node << NODE_SCRIPT
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

async function deleteData(choice) {
  try {
    console.log('🔧 Đang kết nối database...');
    
    switch(choice) {
      case '1':
        console.log('🗑️  Đang xóa TẤT CẢ data...');
        await prisma.repairHistory.deleteMany({});
        await prisma.policy.deleteMany({});
        await prisma.asset.deleteMany({});
        await prisma.user.deleteMany({});
        await prisma.department.deleteMany({});
        await prisma.category.deleteMany({});
        console.log('✅ Đã xóa tất cả data');
        break;
        
      case '2':
        console.log('🗑️  Đang xóa Users...');
        const userCount = await prisma.user.deleteMany({});
        console.log(\`✅ Đã xóa \${userCount.count} users\`);
        break;
        
      case '3':
        console.log('🗑️  Đang xóa Assets...');
        const assetCount = await prisma.asset.deleteMany({});
        console.log(\`✅ Đã xóa \${assetCount.count} assets\`);
        break;
        
      case '4':
        console.log('🗑️  Đang xóa Departments...');
        const deptCount = await prisma.department.deleteMany({});
        console.log(\`✅ Đã xóa \${deptCount.count} departments\`);
        break;
        
      case '5':
        console.log('🗑️  Đang xóa Categories...');
        const catCount = await prisma.category.deleteMany({});
        console.log(\`✅ Đã xóa \${catCount.count} categories\`);
        break;
        
      case '6':
        console.log('🗑️  Đang xóa Repair History...');
        const repairCount = await prisma.repairHistory.deleteMany({});
        console.log(\`✅ Đã xóa \${repairCount.count} repair history records\`);
        break;
        
      case '7':
        console.log('🗑️  Đang xóa Policies...');
        const policyCount = await prisma.policy.deleteMany({});
        console.log(\`✅ Đã xóa \${policyCount.count} policies\`);
        break;
        
      case '8':
        console.log('🗑️  Đang xóa TẤT CẢ và reset database...');
        await prisma.repairHistory.deleteMany({});
        await prisma.policy.deleteMany({});
        await prisma.asset.deleteMany({});
        await prisma.user.deleteMany({});
        await prisma.department.deleteMany({});
        await prisma.category.deleteMany({});
        console.log('✅ Đã xóa tất cả data');
        console.log('');
        console.log('💡 Để seed lại data, chạy:');
        console.log('   cd /var/www/asset-rmg/backend');
        console.log('   npx prisma db seed');
        break;
        
      default:
        console.log('❌ Lựa chọn không hợp lệ');
        process.exit(1);
    }
    
    console.log('');
    console.log('✅ Hoàn thành!');
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
    await prisma.\$disconnect();
  }
}

deleteData('$choice');
NODE_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hoàn thành!"
else
    echo ""
    echo "❌ Có lỗi xảy ra"
    exit 1
fi
