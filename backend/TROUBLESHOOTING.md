# Troubleshooting - Lỗi "Internal server error" khi đăng nhập

## Nguyên nhân có thể:

1. **Prisma Client chưa được generate** - User model không tồn tại
2. **Database chưa có User table** - Migration chưa chạy
3. **User IT chưa được tạo** - Seed chưa chạy
4. **Backend chưa khởi động lại** sau khi generate Prisma client

## Các bước kiểm tra và sửa:

### Bước 1: Kiểm tra Prisma Client đã được generate chưa

```bash
cd backend
npx prisma generate
```

### Bước 2: Kiểm tra User table đã tồn tại chưa

```bash
npx prisma studio
```

Mở http://localhost:5555 và kiểm tra xem có table `users` không.

### Bước 3: Tạo User IT nếu chưa có

```bash
npm run create-admin
```

Hoặc kiểm tra trong Prisma Studio xem user IT đã tồn tại chưa.

### Bước 4: Khởi động lại backend

**QUAN TRỌNG:** Sau khi generate Prisma client, phải khởi động lại backend!

```bash
# Dừng server hiện tại (Ctrl+C)
# Sau đó chạy lại:
npm run start:dev
```

### Bước 5: Kiểm tra logs backend

Xem console của backend để thấy lỗi cụ thể. Lỗi sẽ hiển thị:
- "Property 'user' does not exist" → Chưa generate Prisma client
- "Table 'users' does not exist" → Chưa chạy migration
- "Record not found" → User IT chưa được tạo

## Kiểm tra nhanh:

```bash
# 1. Generate Prisma client
npx prisma generate

# 2. Chạy migration (nếu chưa)
npx prisma migrate dev --name add_users_and_employees_code

# 3. Tạo user IT
npm run create-admin

# 4. Khởi động lại backend
npm run start:dev
```

## Kiểm tra user IT đã tồn tại:

```bash
# Dùng Prisma Studio
npx prisma studio

# Hoặc query trực tiếp bằng psql
"D:\SQL\bin\psql.exe" -U postgres -h localhost -p 5432 -d asset_management
# Sau đó chạy:
SELECT * FROM users WHERE employees_code = 'IT';
```

## Nếu vẫn lỗi:

1. Kiểm tra backend đang chạy tại http://localhost:3000
2. Kiểm tra console backend để xem lỗi cụ thể
3. Đảm bảo database connection đúng trong `.env`
4. Thử test API trực tiếp:

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"employeesCode":"IT"}'
```
