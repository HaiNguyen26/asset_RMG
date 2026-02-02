Write-Host "🔧 Đang sửa lỗi và setup backend..." -ForegroundColor Cyan

# 1. Cài đặt dependencies
Write-Host "📦 Bước 1: Cài đặt dependencies..." -ForegroundColor Yellow
npm install

# 2. Generate Prisma Client
Write-Host "🔨 Bước 2: Generate Prisma Client..." -ForegroundColor Yellow
npx prisma generate

# 3. Chạy migration
Write-Host "🗄️  Bước 3: Chạy migration..." -ForegroundColor Yellow
npx prisma migrate dev --name add_users_and_employees_code

# 4. Seed data (bao gồm IT admin)
Write-Host "🌱 Bước 4: Seed dữ liệu..." -ForegroundColor Yellow
npx prisma db seed

Write-Host "✅ Hoàn tất! Backend đã sẵn sàng." -ForegroundColor Green
Write-Host ""
Write-Host "💡 Tài khoản IT Admin:" -ForegroundColor Cyan
Write-Host "   Mã nhân viên: IT" -ForegroundColor White
Write-Host "   Role: ADMIN" -ForegroundColor White
