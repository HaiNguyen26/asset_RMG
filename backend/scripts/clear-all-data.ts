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
  console.log('🗑️  Bắt đầu xóa toàn bộ dữ liệu...')

  try {
    // Delete all assignments first (foreign key constraint)
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

    // Delete all departments (they will be created from Excel)
    const deletedDepartments = await prisma.department.deleteMany({})
    console.log(`✅ Đã xóa ${deletedDepartments.count} phòng ban (sẽ được tạo lại từ Excel)`)

    console.log('\n✅ Hoàn tất! Tất cả dữ liệu đã được xóa (trừ IT admin user).')
    console.log('📊 Bạn có thể import lại dữ liệu từ Excel.')
    console.log('📝 Phòng ban sẽ được tạo tự động từ Excel, không dùng phòng ban từ seed.')
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
