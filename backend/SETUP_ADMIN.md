# Hướng dẫn tạo tài khoản IT Admin

## Bước 1: Regenerate Prisma Client

Trước khi chạy script `create-admin`, bạn cần regenerate Prisma client để nó nhận các thay đổi trong schema (password và branch):

```bash
cd backend
npx prisma generate
```

## Bước 2: Chạy Migration (nếu chưa chạy)

Nếu bạn chưa chạy migration để thêm cột `password` và `branch` vào database:

```bash
npx prisma migrate dev --name add_password_and_branch_to_user
```

Hoặc nếu migration đã được tạo thủ công, chỉ cần apply:

```bash
npx prisma migrate deploy
```

## Bước 3: Tạo/Cập nhật tài khoản IT Admin

Sau khi Prisma client đã được regenerate và migration đã được apply, chạy:

```bash
npm run create-admin
```

Script sẽ:
- Tạo hoặc cập nhật user IT với:
  - Mã nhân viên: `IT`
  - Mật khẩu: `Hainguyen261097` (đã được hash)
  - Branch: `Hà Nội`
  - Role: `ADMIN`

## Thông tin đăng nhập

Sau khi chạy thành công, bạn có thể đăng nhập với:
- **Mã nhân viên:** `IT`
- **Mật khẩu:** `Hainguyen261097`

## Lưu ý

- Nếu gặp lỗi "Cannot find module 'bcrypt'", chạy: `npm install`
- Nếu gặp lỗi về Prisma types, đảm bảo đã chạy `npx prisma generate`
- Nếu gặp lỗi về database connection, kiểm tra file `.env` có `DATABASE_URL` đúng không
