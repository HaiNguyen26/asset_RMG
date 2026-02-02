# Hướng dẫn chạy Migration cho Password và Branch

## Bước 1: Chạy Migration

Migration file đã được tạo tại: `prisma/migrations/20260202120000_add_password_and_branch_to_user/migration.sql`

Chạy migration:
```bash
cd backend
npx prisma migrate dev
```

Hoặc nếu muốn apply migration mà không tạo migration mới:
```bash
npx prisma migrate deploy
```

## Bước 2: Cập nhật Password và Branch cho User IT

Sau khi migration chạy thành công, cập nhật user IT với password và branch:

```bash
npm run create-admin
```

Hoặc chạy seed:
```bash
npm run prisma:seed
```

## Bước 3 (Tùy chọn): Set NOT NULL cho Password

Sau khi tất cả users đã có password, bạn có thể tạo migration để set NOT NULL:

1. Cập nhật schema.prisma: đổi `password String?` thành `password String`
2. Chạy: `npx prisma migrate dev --name set_password_not_null`

## Lưu ý

- Migration hiện tại thêm cột `password` và `branch` với giá trị nullable để tránh lỗi với dữ liệu hiện có
- Sau khi chạy `create-admin` hoặc `seed`, user IT sẽ có:
  - Password: `RMG123@` (đã được hash)
  - Branch: `Hà Nội`
