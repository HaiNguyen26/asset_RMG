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
  console.log('📝 Đang thêm/chỉnh sửa chính sách Cấp phát thiết bị...')

  const policyContent = `<h2>1. Đối tượng áp dụng</h2>
<p>Toàn thể nhân viên chính thức hoặc nhân viên thử việc (theo yêu cầu đặc thù của vị trí công việc) tại <strong>RMG Vietnam</strong>.</p>

<h2>2. Quy định trong thời gian thử việc (02 tháng đầu)</h2>
<ul>
  <li><strong>Thiết bị:</strong> Nhân viên sử dụng máy tính cá nhân (BYOD).</li>
  <li><strong>Hỗ trợ kỹ thuật:</strong> Bộ phận IT chịu trách nhiệm cài đặt các phần mềm bản quyền, cấu hình hệ thống và thiết lập bảo mật cần thiết trên máy cá nhân để phục vụ công việc.</li>
  <li><strong>Xét duyệt trang bị:</strong> Sau khi kết thúc thử việc, Quản lý trực tiếp sẽ đánh giá năng lực thực tế. Nếu đạt yêu cầu chuyên môn cao, Công ty sẽ tiến hành mua máy mới theo định mức quy định.</li>
</ul>

<h2>3. Định mức và tiêu chuẩn thiết bị (Khi vào chính thức)</h2>
<p>Công ty trang bị công cụ dựa trên yêu cầu hiệu suất của từng vị trí:</p>

<div class="overflow-x-auto my-6">
  <table class="min-w-full border-collapse border border-slate-300">
    <thead>
      <tr class="bg-indigo-50">
        <th class="border border-slate-300 px-4 py-3 text-left text-sm font-bold text-slate-700">Vị trí công tác</th>
        <th class="border border-slate-300 px-4 py-3 text-left text-sm font-bold text-slate-700">Đặc thù phần mềm</th>
        <th class="border border-slate-300 px-4 py-3 text-left text-sm font-bold text-slate-700">Ngân sách tối đa (VNĐ)</th>
        <th class="border border-slate-300 px-4 py-3 text-left text-sm font-bold text-slate-700">Yêu cầu cấu hình tối thiểu</th>
      </tr>
    </thead>
    <tbody>
      <tr class="hover:bg-slate-50">
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-700 font-medium">Thiết kế bản vẽ 3D</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-600">SolidWorks, Inventor, Catia, Render...</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-700 font-semibold">30.000.000 - 45.000.000</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-600">CPU i7/i9 (H series), RAM 32GB-64GB, Card đồ họa RTX 4060+.</td>
      </tr>
      <tr class="hover:bg-slate-50 bg-slate-50/50">
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-700 font-medium">Lập trình PLC & Automation</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-600">TIA Portal, Studio 5000, VMware...</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-700 font-semibold">25.000.000 - 30.000.000</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-600">Dòng Workstation bền bỉ, RAM 32GB, Đầy đủ cổng RJ45, USB.</td>
      </tr>
      <tr class="hover:bg-slate-50">
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-700 font-medium">Văn phòng / Admin</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-600">Office, ERP, Browser, Meeting.</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-700 font-semibold">15.000.000 - 20.000.000</td>
        <td class="border border-slate-300 px-4 py-3 text-sm text-slate-600">CPU i5, RAM 16GB, thiết kế mỏng nhẹ, pin bền.</td>
      </tr>
    </tbody>
  </table>
</div>

<h2>4. Thủ tục bàn giao và trách nhiệm bảo quản</h2>
<ul>
  <li><strong>Bàn giao:</strong> IT kiểm tra tình trạng máy, dán tem niêm phong và lập Biên bản bàn giao. Nhân viên kiểm tra ngoại quan và ký xác nhận tài sản.</li>
  <li><strong>Sử dụng:</strong> Thiết bị là tài sản của Công ty, chỉ sử dụng cho mục đích công việc.</li>
  <li><strong>Nghiêm cấm:</strong> Tự ý tháo dỡ, tráo đổi linh kiện, cài đặt phần mềm độc hại/lậu hoặc tự ý sửa chữa bên ngoài khi chưa có chỉ định của IT.</li>
</ul>`

  // Find IT admin user
  const itAdmin = await prisma.user.findUnique({
    where: { employeesCode: 'IT' },
  })

  if (!itAdmin) {
    throw new Error('IT Admin user not found. Please run seed first.')
  }

  // Upsert policy
  const policy = await prisma.policy.upsert({
    where: { category: 'equipment-assignment' },
    update: {
      title: 'Chính Sách Cấp Phát Thiết Bị',
      content: policyContent,
      updatedById: itAdmin.id,
    },
    create: {
      category: 'equipment-assignment',
      title: 'Chính Sách Cấp Phát Thiết Bị',
      content: policyContent,
      order: 1,
      updatedById: itAdmin.id,
    },
  })

  console.log('✅ Đã thêm/chỉnh sửa chính sách Cấp phát thiết bị thành công!')
  console.log(`   Category: ${policy.category}`)
  console.log(`   Title: ${policy.title}`)
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
