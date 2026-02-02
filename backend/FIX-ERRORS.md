# Hướng dẫn sửa lỗi Backend

## Các lỗi hiện tại:
1. ❌ Missing modules: `@nestjs/jwt`, `@nestjs/passport`, `passport-jwt`
2. ❌ Prisma client chưa có User model (chưa generate sau khi thêm schema)
3. ✅ Đã sửa: Duplicate property `errors` trong importExcel

## ⚡ Cách nhanh nhất - Chạy một lệnh:

```bash
cd backend
npm run fix-all
```

Lệnh này sẽ tự động:
- ✅ Cài đặt dependencies
- ✅ Generate Prisma Client
- ✅ Chạy migration
- ✅ Seed dữ liệu (bao gồm IT Admin)

## Hoặc chạy từng bước:

### Bước 1: Cài đặt dependencies
```bash
cd backend
npm install
```

### Bước 2: Generate Prisma Client (QUAN TRỌNG!)
```bash
npx prisma generate
```

### Bước 3: Chạy Migration
```bash
npx prisma migrate dev --name add_users_and_employees_code
```

### Bước 4: Seed dữ liệu (tạo IT Admin)
```bash
npx prisma db seed
```

### Bước 5: Kiểm tra lại
```bash
npm run start:dev
```

## Nếu vẫn còn lỗi:

### Clear cache và rebuild:
```bash
# Xóa node_modules và reinstall
rm -rf node_modules
npm install

# Generate lại Prisma client
npx prisma generate

# Build lại
npm run build
```

## Lưu ý:
- Đảm bảo PostgreSQL đang chạy
- Đảm bảo database `asset_management` đã được tạo
- Kiểm tra file `.env` có `DATABASE_URL` đúng
