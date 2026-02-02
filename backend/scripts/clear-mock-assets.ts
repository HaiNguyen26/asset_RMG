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

async function clearMockAssets() {
  try {
    // List of mock asset codes to delete
    const mockAssetCodes = ['LT-001', 'LT-002', 'LT-003', 'MK-001', 'PR-001']

    console.log('🗑️  Đang xóa các asset mẫu...')
    
    for (const code of mockAssetCodes) {
      const deleted = await prisma.asset.deleteMany({
        where: { code },
      })
      if (deleted.count > 0) {
        console.log(`   ✓ Đã xóa: ${code}`)
      }
    }

    // Also delete any other assets that might exist (optional - be careful!)
    // Uncomment the following if you want to delete ALL assets:
    /*
    const allDeleted = await prisma.asset.deleteMany({})
    console.log(`   ✓ Đã xóa tổng cộng ${allDeleted.count} assets`)
    */

    console.log('✅ Hoàn thành! Tất cả asset mẫu đã được xóa.')
    console.log('📊 Bây giờ bạn có thể import dữ liệu từ Excel.')
  } catch (error: any) {
    console.error('❌ Lỗi khi xóa assets:', error.message)
    process.exit(1)
  } finally {
    await prisma.$disconnect()
    await pool.end()
  }
}

clearMockAssets()
