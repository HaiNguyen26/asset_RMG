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

async function clearMockDepartments() {
  try {
    // List of mock department codes to delete
    const mockDepartmentCodes = ['TECH', 'ADMIN', 'ACCOUNT', 'WAREHOUSE']

    console.log('🗑️  Đang xóa các phòng ban mẫu...')

    for (const code of mockDepartmentCodes) {
      const deleted = await prisma.department.deleteMany({
        where: { code },
      })
      if (deleted.count > 0) {
        console.log(`   ✓ Đã xóa: ${code}`)
      }
    }

    console.log('✅ Hoàn thành! Tất cả phòng ban mẫu đã được xóa.')
    console.log('📊 Bây giờ bạn có thể import departments từ Excel (nếu có) hoặc tạo mới thủ công.')
  } catch (error: any) {
    console.error('❌ Lỗi khi xóa departments:', error.message)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
    await pool.end()
  }
}

clearMockDepartments()
