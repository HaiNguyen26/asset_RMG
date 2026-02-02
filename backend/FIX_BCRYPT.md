# Sửa lỗi bcrypt_lib.node

## Vấn đề
Lỗi `Cannot find module 'bcrypt_lib.node'` xảy ra khi native bindings của `bcrypt` chưa được build đúng cách.

## Giải pháp

### Cách 1: Rebuild bcrypt (Khuyến nghị)
```bash
cd backend
npm rebuild bcrypt
```

### Cách 2: Cài lại bcrypt
```bash
cd backend
npm uninstall bcrypt
npm install bcrypt
```

### Cách 3: Cài lại toàn bộ dependencies
```bash
cd backend
rm -rf node_modules
npm install
```

## Sau khi sửa xong

Chạy lại script tạo admin:
```bash
npm run create-admin
```

## Lưu ý

- Nếu vẫn lỗi, đảm bảo bạn đã cài đặt build tools (Visual Studio Build Tools trên Windows)
- Hoặc thử cài `bcryptjs` thay vì `bcrypt` (pure JavaScript, không cần native bindings)
