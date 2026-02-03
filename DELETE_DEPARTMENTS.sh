#!/bin/bash
# Script xóa departments từ database

cd /var/www/asset-rmg/backend

echo "🗑️  Xóa departments từ database..."
echo "===================================="

# Kiểm tra .env
if [ ! -f .env ]; then
    echo "❌ File .env không tồn tại!"
    exit 1
fi

# Load .env
export $(cat .env | grep -v '^#' | xargs)

echo ""
echo "📋 Departments hiện có trong database:"
node -e "
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

prisma.department.findMany().then(depts => {
  console.log(JSON.stringify(depts, null, 2));
  process.exit(0);
}).catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
"

echo ""
echo "⚠️  Bạn có muốn xóa các departments này không? (y/n)"
read -r response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "❌ Hủy bỏ. Không xóa gì."
    exit 0
fi

echo ""
echo "🗑️  Đang xóa departments..."

node -e "
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function deleteDepartments() {
  try {
    // Xóa tất cả departments
    const result = await prisma.department.deleteMany({});
    console.log('✅ Đã xóa', result.count, 'departments');
    
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

deleteDepartments();
"

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "📋 Kiểm tra lại:"
curl -s http://localhost:4001/api/departments | jq . || curl -s http://localhost:4001/api/departments
