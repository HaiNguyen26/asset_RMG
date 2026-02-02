import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'
import * as bcrypt from 'bcrypt'

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is not set')
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL })
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

async function main() {
  const deptTech = await prisma.department.upsert({
    where: { code: 'TECH' },
    update: {},
    create: { code: 'TECH', name: 'Phòng Công nghệ' },
  })
  const deptAdmin = await prisma.department.upsert({
    where: { code: 'ADMIN' },
    update: {},
    create: { code: 'ADMIN', name: 'Phòng Hành chính' },
  })
  const deptAccount = await prisma.department.upsert({
    where: { code: 'ACCOUNT' },
    update: {},
    create: { code: 'ACCOUNT', name: 'Phòng Kế toán' },
  })
  const deptWarehouse = await prisma.department.upsert({
    where: { code: 'WAREHOUSE' },
    update: {},
    create: { code: 'WAREHOUSE', name: 'Kho' },
  })

  const catLaptop = await prisma.assetCategory.upsert({
    where: { slug: 'laptop' },
    update: {},
    create: {
      slug: 'laptop',
      name: 'Laptop',
      description: 'Máy tính xách tay',
    },
  })
  const catAccessory = await prisma.assetCategory.upsert({
    where: { slug: 'it_accessory' },
    update: {},
    create: {
      slug: 'it_accessory',
      name: 'Phụ kiện IT',
      description: 'Chuột, bàn phím, màn hình...',
    },
  })
  const catTech = await prisma.assetCategory.upsert({
    where: { slug: 'tech_equipment' },
    update: {},
    create: {
      slug: 'tech_equipment',
      name: 'Thiết bị Kỹ thuật',
      description: 'Máy in, máy chiếu, thiết bị đo...',
    },
  })

  // Create IT Admin user
  const hashedPassword = await bcrypt.hash('Hainguyen261097', 10)
  await prisma.user.upsert({
    where: { employeesCode: 'IT' },
    update: {
      password: hashedPassword,
      branch: 'Hà Nội',
    },
    create: {
      employeesCode: 'IT',
      password: hashedPassword,
      name: 'IT Admin',
      email: 'it.admin@company.com',
      branch: 'Hà Nội',
      role: 'ADMIN',
      departmentId: deptTech.id,
    },
  })

  // Mock assets removed - use Excel import instead
  console.log('✅ Seed completed.')
  console.log('📝 Departments, Categories, and IT Admin user have been created.')
  console.log('📊 Use Excel import to add assets.')
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
