# 🔧 Fix: Database Authentication Failed

## ❌ Lỗi hiện tại

```
Error: P1000: Authentication failed against database server, 
the provided database credentials for 'asset_user' are not valid.
```

## ✅ Giải pháp: Tạo/Sửa Database User

### Bước 1: Kiểm tra user có tồn tại không

```bash
# Vào PostgreSQL
sudo -u postgres psql

# Kiểm tra các users
\du

# Tìm user `asset_user` trong danh sách
```

### Bước 2: Tạo hoặc sửa user với password đúng

#### Nếu user chưa tồn tại:

```sql
-- Tạo user với password
CREATE USER asset_user WITH PASSWORD 'Hainguyen261097';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

-- Connect vào database
\c asset_rmg_db

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;

-- Thoát
\q
```

#### Nếu user đã tồn tại nhưng password sai:

```sql
-- Sửa password cho user
ALTER USER asset_user WITH PASSWORD 'Hainguyen261097';

-- Đảm bảo có quyền truy cập database
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

-- Connect vào database
\c asset_rmg_db

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;

-- Thoát
\q
```

### Bước 3: Kiểm tra database đã được tạo

```sql
-- Trong PostgreSQL shell
\l

-- Tìm database `asset_rmg_db` trong danh sách
```

Nếu chưa có, tạo database:

```sql
CREATE DATABASE asset_rmg_db;
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;
\q
```

### Bước 4: Test connection

```bash
# Test connection với user và password
sudo -u postgres psql -U asset_user -d asset_rmg_db
# Nhập password: Hainguyen261097

# Nếu connect thành công, bạn sẽ vào PostgreSQL shell
# Thoát bằng: \q
```

### Bước 5: Kiểm tra file .env

```bash
cd /var/www/asset-rmg/backend

# Xem nội dung file .env
cat .env
```

**Đảm bảo có dòng:**
```env
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
```

Nếu sai, sửa lại:

```bash
nano .env
```

### Bước 6: Chạy lại Prisma migrate

```bash
cd /var/www/asset-rmg/backend

# Generate Prisma client
npx prisma generate

# Chạy migrations
npx prisma migrate deploy

# Kiểm tra status
npx prisma migrate status
```

---

## 🔍 Script tự động (Copy toàn bộ và chạy)

```bash
# Tạo user và database (chạy từng lệnh)
sudo -u postgres psql << 'EOF'
-- Tạo database nếu chưa có
CREATE DATABASE asset_rmg_db;

-- Tạo user hoặc sửa password
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'asset_user') THEN
        ALTER USER asset_user WITH PASSWORD 'Hainguyen261097';
    ELSE
        CREATE USER asset_user WITH PASSWORD 'Hainguyen261097';
    END IF;
END
$$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

-- Connect và grant schema privileges
\c asset_rmg_db
GRANT ALL ON SCHEMA public TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO asset_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO asset_user;

\q
EOF

# Kiểm tra connection
sudo -u postgres psql -U asset_user -d asset_rmg_db -c "SELECT 1;"

# Nếu OK, chạy Prisma migrate
cd /var/www/asset-rmg/backend
npx prisma migrate deploy
```

---

## 🐛 Troubleshooting

### Lỗi: "role does not exist"

**Giải pháp**: User chưa được tạo, chạy lệnh CREATE USER ở trên.

### Lỗi: "database does not exist"

**Giải pháp**: 
```sql
CREATE DATABASE asset_rmg_db;
```

### Lỗi: "permission denied"

**Giải pháp**: 
```sql
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;
\c asset_rmg_db
GRANT ALL ON SCHEMA public TO asset_user;
```

### Vẫn báo authentication failed

**Kiểm tra:**
1. Password trong `.env` có đúng không: `cat /var/www/asset-rmg/backend/.env`
2. User có tồn tại không: `sudo -u postgres psql -c "\du"`
3. Test connection trực tiếp: `sudo -u postgres psql -U asset_user -d asset_rmg_db`

---

## ✅ Checklist

- [ ] Database `asset_rmg_db` đã được tạo
- [ ] User `asset_user` đã được tạo với password `Hainguyen261097`
- [ ] User có quyền truy cập database
- [ ] File `.env` có `DATABASE_URL` đúng
- [ ] Test connection thành công
- [ ] `npx prisma migrate deploy` chạy thành công

---

## 💡 Lưu ý

- Password trong PostgreSQL phải khớp với password trong file `.env`
- Đảm bảo user có đủ quyền (ALL PRIVILEGES)
- Sau khi sửa password, cần restart backend nếu đang chạy
