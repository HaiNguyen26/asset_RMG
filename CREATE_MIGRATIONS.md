# 🔧 Tạo Migrations cho Database

## ❌ Vấn đề

```
No migration found in `prisma/migrations`
No pending migrations to apply.
```

## ✅ Giải pháp: Tạo migrations từ schema

### Cách 1: Tạo migrations mới (Khuyến nghị)

```bash
cd /var/www/asset-rmg/backend

# Tạo migrations từ schema hiện tại
npx prisma migrate dev --name init

# Sau đó deploy migrations
npx prisma migrate deploy
```

**Lưu ý**: `prisma migrate dev` sẽ:
- Tạo migration files trong `prisma/migrations/`
- Apply migrations vào database
- Generate Prisma client

### Cách 2: Push schema trực tiếp (Nếu database trống)

Nếu database chưa có tables nào, có thể push schema trực tiếp:

```bash
cd /var/www/asset-rmg/backend

# Push schema trực tiếp (không tạo migration files)
npx prisma db push

# Sau đó tạo migration từ database hiện tại
npx prisma migrate dev --name init --create-only
npx prisma migrate deploy
```

### Cách 3: Tạo migration từ database hiện có

Nếu database đã có schema (từ lần chạy trước):

```bash
cd /var/www/asset-rmg/backend

# Introspect database để tạo schema
npx prisma db pull

# Tạo migration từ schema
npx prisma migrate dev --name init
```

---

## 📝 Chi tiết các bước

### Bước 1: Kiểm tra database có tables chưa

```bash
sudo -u postgres psql -d asset_rmg_db -c "\dt"
```

**Nếu không có tables**: Database trống, cần tạo migrations  
**Nếu có tables**: Database đã có schema, cần sync

### Bước 2: Tạo migrations

```bash
cd /var/www/asset-rmg/backend

# Option A: Tạo migrations mới (nếu database trống)
npx prisma migrate dev --name init

# Option B: Nếu database đã có schema, tạo migration từ schema
npx prisma migrate dev --name sync_existing_schema --create-only
npx prisma migrate resolve --applied init  # Đánh dấu migration đã apply
```

### Bước 3: Deploy migrations

```bash
# Deploy migrations
npx prisma migrate deploy

# Kiểm tra status
npx prisma migrate status
```

### Bước 4: Generate Prisma client

```bash
npx prisma generate
```

---

## 🔍 Kiểm tra migrations đã được tạo

```bash
# Xem migrations trong thư mục
ls -la /var/www/asset-rmg/backend/prisma/migrations/

# Xem nội dung migration
cat /var/www/asset-rmg/backend/prisma/migrations/*/migration.sql
```

---

## 🐛 Troubleshooting

### Lỗi: "Migration engine failed to connect"

**Giải pháp**: Kiểm tra `.env` và database connection

```bash
cat .env | grep DATABASE_URL
```

### Lỗi: "Database schema is not in sync"

**Giải pháp**: 
```bash
# Reset database (CẨN THẬN - sẽ xóa dữ liệu!)
npx prisma migrate reset

# Hoặc push schema trực tiếp
npx prisma db push
```

### Migrations đã được tạo nhưng không apply

```bash
# Kiểm tra migrations
npx prisma migrate status

# Apply migrations thủ công nếu cần
npx prisma migrate deploy
```

---

## ✅ Sau khi tạo migrations thành công

```bash
# 1. Generate Prisma client
npx prisma generate

# 2. Seed data (nếu cần)
npx prisma db seed

# 3. Build backend
npm run build

# 4. Start với PM2
cd /var/www/asset-rmg
pm2 start ecosystem.config.js
```

---

## 💡 Lưu ý

- `prisma migrate dev`: Dùng cho development, tự động apply migrations
- `prisma migrate deploy`: Dùng cho production, chỉ apply pending migrations
- `prisma db push`: Push schema trực tiếp, không tạo migration files (chỉ dùng development)
