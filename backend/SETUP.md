# Hướng dẫn Setup Database

## Lỗi ECONNREFUSED

Lỗi này xảy ra khi không thể kết nối đến PostgreSQL server. Hãy làm theo các bước sau:

## Bước 1: Kiểm tra PostgreSQL đang chạy

**Windows:**
```bash
# Kiểm tra service PostgreSQL
sc query postgresql-x64-XX  # Thay XX bằng version của bạn

# Hoặc kiểm tra trong Services (services.msc)
# Tìm "PostgreSQL" và đảm bảo nó đang "Running"
```

**Nếu PostgreSQL chưa chạy:**
```bash
# Khởi động service
net start postgresql-x64-XX
```

**Hoặc:** Mở **Services** (Win + R → `services.msc`), tìm PostgreSQL và Start.

## Bước 2: Tạo Database

Chạy script tạo database:

```bash
npm run db:create
```

Script này sẽ:
- Kết nối đến PostgreSQL server
- Tạo database `asset_management` nếu chưa có

## Bước 3: Chạy Migration

Sau khi database đã được tạo:

```bash
npx prisma migrate dev --name init
```

Lệnh này sẽ:
- Tạo các bảng trong database
- Chạy migration files

## Bước 4: Seed Database

Cuối cùng, seed dữ liệu mẫu:

```bash
npx prisma db seed
```

## Hoặc chạy tất cả một lần:

```bash
npm run db:setup
```

## Kiểm tra kết nối thủ công

Nếu vẫn gặp lỗi, kiểm tra kết nối bằng psql:

```bash
psql -U postgres -h localhost -p 5432
# Nhập password: Hainguyen261097
```

Hoặc kiểm tra DATABASE_URL trong `.env`:
```
DATABASE_URL="postgresql://postgres:Hainguyen261097@localhost:5432/asset_management?schema=public"
```

## Troubleshooting

1. **ECONNREFUSED**: PostgreSQL server không chạy → Khởi động service
2. **Password authentication failed**: Sai password → Kiểm tra `.env`
3. **Database does not exist**: Chưa tạo database → Chạy `npm run db:create`
4. **Port 5432 in use**: Port bị chiếm → Kiểm tra PostgreSQL config
