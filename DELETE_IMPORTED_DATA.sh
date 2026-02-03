#!/bin/bash
# Script xóa data đã được import để import lại

set -e

echo "🗑️  Xóa Data Đã Import"
echo "======================="

cd /var/www/asset-rmg/backend

# Đảm bảo Prisma Client đã generate
echo ""
echo "🔧 Generating Prisma Client..."
npx prisma generate

# Hiển thị menu
echo ""
echo "Chọn loại data đã import muốn xóa:"
echo "  1) Xóa Assets đã import (giữ lại categories, departments)"
echo "  2) Xóa Users đã import (giữ lại IT admin)"
echo "  3) Xóa Departments đã import"
echo "  4) Xóa Categories đã import"
echo "  5) Xóa Repair History đã import"
echo "  6) Xóa Policies đã import"
echo "  7) Xóa TẤT CẢ data đã import (Assets, Users, Departments, Categories)"
echo "  8) Xóa TẤT CẢ (bao gồm cả Repair History và Policies)"
echo ""
read -p "Chọn (1-8): " choice

# Xác nhận
echo ""
echo "⚠️  Bạn sắp xóa data đã import!"
read -p "Nhập 'yes' để xác nhận: " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

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

async function deleteImportedData(choice) {
  try {
    console.log('🔧 Đang kết nối database...');
    
    switch(choice) {
      case '1':
        console.log('🗑️  Đang xóa Assets đã import...');
        const assetCount = await prisma.asset.deleteMany({});
        console.log(\`✅ Đã xóa \${assetCount.count} assets\`);
        console.log('💡 Categories và Departments vẫn được giữ lại');
        break;
        
      case '2':
        console.log('🗑️  Đang xóa Users đã import (giữ lại IT admin)...');
        const userCount = await prisma.user.deleteMany({
          where: {
            employeesCode: {
              not: 'IT'
            }
          }
        });
        console.log(\`✅ Đã xóa \${userCount.count} users (giữ lại IT admin)\`);
        break;
        
      case '3':
        console.log('🗑️  Đang xóa Departments đã import...');
        const deptCount = await prisma.department.deleteMany({});
        console.log(\`✅ Đã xóa \${deptCount.count} departments\`);
        console.log('⚠️  Lưu ý: Assets liên quan có thể bị ảnh hưởng');
        break;
        
      case '4':
        console.log('🗑️  Đang xóa Categories đã import...');
        const catCount = await prisma.category.deleteMany({});
        console.log(\`✅ Đã xóa \${catCount.count} categories\`);
        console.log('⚠️  Lưu ý: Assets liên quan có thể bị ảnh hưởng');
        break;
        
      case '5':
        console.log('🗑️  Đang xóa Repair History đã import...');
        const repairCount = await prisma.repairHistory.deleteMany({});
        console.log(\`✅ Đã xóa \${repairCount.count} repair history records\`);
        break;
        
      case '6':
        console.log('🗑️  Đang xóa Policies đã import...');
        const policyCount = await prisma.policy.deleteMany({});
        console.log(\`✅ Đã xóa \${policyCount.count} policies\`);
        break;
        
      case '7':
        console.log('🗑️  Đang xóa TẤT CẢ data đã import...');
        console.log('   - Xóa Assets...');
        const aCount = await prisma.asset.deleteMany({});
        console.log(\`     ✅ Đã xóa \${aCount.count} assets\`);
        
        console.log('   - Xóa Users (giữ lại IT admin)...');
        const uCount = await prisma.user.deleteMany({
          where: { employeesCode: { not: 'IT' } }
        });
        console.log(\`     ✅ Đã xóa \${uCount.count} users\`);
        
        console.log('   - Xóa Departments...');
        const dCount = await prisma.department.deleteMany({});
        console.log(\`     ✅ Đã xóa \${dCount.count} departments\`);
        
        console.log('   - Xóa Categories...');
        const cCount = await prisma.category.deleteMany({});
        console.log(\`     ✅ Đã xóa \${cCount.count} categories\`);
        
        console.log('');
        console.log('✅ Đã xóa tất cả data đã import');
        console.log('💡 Bây giờ bạn có thể import lại data từ Excel');
        break;
        
      case '8':
        console.log('🗑️  Đang xóa TẤT CẢ data đã import (bao gồm Repair History và Policies)...');
        console.log('   - Xóa Repair History...');
        const rCount = await prisma.repairHistory.deleteMany({});
        console.log(\`     ✅ Đã xóa \${rCount.count} records\`);
        
        console.log('   - Xóa Policies...');
        const pCount = await prisma.policy.deleteMany({});
        console.log(\`     ✅ Đã xóa \${pCount.count} records\`);
        
        console.log('   - Xóa Assets...');
        const aCount2 = await prisma.asset.deleteMany({});
        console.log(\`     ✅ Đã xóa \${aCount2.count} assets\`);
        
        console.log('   - Xóa Users (giữ lại IT admin)...');
        const uCount2 = await prisma.user.deleteMany({
          where: { employeesCode: { not: 'IT' } }
        });
        console.log(\`     ✅ Đã xóa \${uCount2.count} users\`);
        
        console.log('   - Xóa Departments...');
        const dCount2 = await prisma.department.deleteMany({});
        console.log(\`     ✅ Đã xóa \${dCount2.count} departments\`);
        
        console.log('   - Xóa Categories...');
        const cCount2 = await prisma.category.deleteMany({});
        console.log(\`     ✅ Đã xóa \${cCount2.count} categories\`);
        
        console.log('');
        console.log('✅ Đã xóa TẤT CẢ data đã import');
        console.log('💡 Bây giờ bạn có thể import lại data từ Excel');
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

deleteImportedData('$choice');
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
