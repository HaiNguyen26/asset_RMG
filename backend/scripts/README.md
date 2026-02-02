# Database Setup Scripts

## Tạo Database

Script này sẽ tự động tạo database PostgreSQL nếu chưa tồn tại.

```bash
npm run db:create
```

## Setup hoàn chỉnh (Tạo DB + Migration + Seed)

Chạy một lệnh để setup toàn bộ:

```bash
npm run db:setup
```

Lệnh này sẽ:
1. Tạo database `asset_management` (nếu chưa có)
2. Chạy Prisma migration để tạo tables
3. Seed dữ liệu mẫu

## Yêu cầu

- PostgreSQL server đang chạy
- File `.env` đã được cấu hình với `DATABASE_URL` đúng
- User PostgreSQL có quyền tạo database
