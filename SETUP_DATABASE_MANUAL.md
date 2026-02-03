# 📝 Setup Database - Hướng dẫn từng bước thủ công

## ⚠️ Nếu gặp lỗi khi chạy script, làm thủ công từng bước:

### Bước 1: Vào PostgreSQL

```bash
sudo -u postgres psql
```

Bạn sẽ thấy prompt: `postgres=#`

### Bước 2: Tạo database (nếu chưa có)

```sql
CREATE DATABASE asset_rmg_db;
```

**Nếu báo lỗi "already exists"**: Bỏ qua bước này, database đã có rồi.

### Bước 3: Tạo user hoặc sửa password

```sql
-- Kiểm tra user có tồn tại không
SELECT usename FROM pg_user WHERE usename = 'asset_user';
```

**Nếu user chưa có**, tạo mới:
```sql
CREATE USER asset_user WITH PASSWORD 'Hainguyen261097';
```

**Nếu user đã có**, sửa password:
```sql
ALTER USER asset_user WITH PASSWORD 'Hainguyen261097';
```

### Bước 4: Grant privileges trên database

```sql
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;
```

### Bước 5: Connect vào database và grant schema privileges

```sql
-- Connect vào database asset_rmg_db
\c asset_rmg_db
```

Bạn sẽ thấy prompt đổi thành: `asset_rmg_db=#`

Sau đó chạy:
```sql
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;
```

### Bước 6: Thoát PostgreSQL

```sql
\q
```

### Bước 7: Test connection

```bash
# Test với user asset_user
sudo -u postgres psql -U asset_user -d asset_rmg_db -c "SELECT 1;"
```

**Kết quả mong đợi**: Hiển thị số `1`

### Bước 8: Kiểm tra file .env

```bash
cd /var/www/asset-rmg/backend
cat .env
```

**Đảm bảo có dòng:**
```
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
```

### Bước 9: Chạy Prisma migrate

```bash
cd /var/www/asset-rmg/backend
npx prisma generate
npx prisma migrate deploy
```

---

## 🔍 Kiểm tra nhanh

```bash
# Kiểm tra database có tồn tại không
sudo -u postgres psql -c "\l" | grep asset_rmg_db

# Kiểm tra user có tồn tại không
sudo -u postgres psql -c "\du" | grep asset_user

# Test connection
sudo -u postgres psql -U asset_user -d asset_rmg_db -c "SELECT current_database(), current_user;"
```

---

## ✅ Checklist

- [ ] Database `asset_rmg_db` đã được tạo
- [ ] User `asset_user` đã được tạo với password `Hainguyen261097`
- [ ] User có quyền trên database
- [ ] User có quyền trên schema public
- [ ] Test connection thành công
- [ ] File `.env` có `DATABASE_URL` đúng
- [ ] `npx prisma migrate deploy` chạy thành công
