import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is not set')
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL })
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

async function main() {
  console.log('🗑️  Bắt đầu xóa toàn bộ dữ liệu (giữ lại IT user, categories, departments)...')

  try {
    // Delete all repair history first (references assets and users)
    const deletedRepairs = await prisma.repairHistory.deleteMany({})
    console.log(`✅ Đã xóa ${deletedRepairs.count} bản ghi Repair History`)

    // Delete all policies (references users)
    const deletedPolicies = await prisma.policy.deleteMany({})
    console.log(`✅ Đã xóa ${deletedPolicies.count} bản ghi Policy`)

    // Delete all assignments (foreign key constraint)
    const deletedAssignments = await prisma.assignment.deleteMany({})
    console.log(`✅ Đã xóa ${deletedAssignments.count} bản ghi Assignment`)

    // Delete all assets
    const deletedAssets = await prisma.asset.deleteMany({})
    console.log(`✅ Đã xóa ${deletedAssets.count} bản ghi Asset`)

    // Delete all users except IT admin (employeesCode: 'IT')
    const deletedUsers = await prisma.user.deleteMany({
      where: {
        employeesCode: {
          not: 'IT',
        },
      },
    })
    console.log(`✅ Đã xóa ${deletedUsers.count} user (giữ lại IT admin)`)

    // Keep categories and departments - they are needed for import

    console.log('\n✅ Hoàn tất! Đã xóa:')
    console.log('   - Tất cả Assets')
    console.log('   - Tất cả Users (trừ IT)')
    console.log('   - Tất cả Repair History')
    console.log('   - Tất cả Policies')
    console.log('   - Tất cả Assignments')
    console.log('\n📋 Giữ lại:')
    console.log('   - IT Admin user (employeesCode: IT)')
    console.log('   - Categories (Laptop, Phụ kiện IT, Thiết bị Kỹ thuật)')
    console.log('   - Departments (sẽ được tạo tự động từ Excel khi import)')
    console.log('\n📊 Bạn có thể import lại dữ liệu từ Excel.')
  } catch (error) {
    console.error('❌ Lỗi khi xóa dữ liệu:', error)
    throw error
  }
}

main()
  .then(async () => {
    await prisma.$disconnect()
    await pool.end()
  })
  .catch(async (e) => {
    console.error(e)
    await prisma.$disconnect()
    await pool.end()
    process.exit(1)
  })
