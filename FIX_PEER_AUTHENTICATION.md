# 🔧 Fix: Peer Authentication Failed

## ❌ Lỗi hiện tại

```
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: 
FATAL: Peer authentication failed for user "asset_user"
```

## ✅ Giải pháp

### Cách 1: Sửa pg_hba.conf để cho phép password authentication (Khuyến nghị)

#### Bước 1: Backup file pg_hba.conf

```bash
cp /etc/postgresql/*/main/pg_hba.conf /etc/postgresql/*/main/pg_hba.conf.backup
```

#### Bước 2: Mở file pg_hba.conf

```bash
nano /etc/postgresql/*/main/pg_hba.conf
```

Hoặc tìm file chính xác:
```bash
find /etc/postgresql -name pg_hba.conf
```

#### Bước 3: Tìm và sửa dòng local connection

Tìm dòng có dạng:
```
local   all             all                                     peer
```

Hoặc:
```
local   all             all                                     md5
```

**Sửa thành:**
```
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

#### Bước 4: Reload PostgreSQL

```bash
systemctl reload postgresql
```

#### Bước 5: Test connection lại

```bash
# Test với password
PGPASSWORD=Hainguyen261097 psql -U asset_user -d asset_rmg_db -h localhost -c "SELECT 1;"
```

---

### Cách 2: Test connection từ ứng dụng (Đơn giản hơn)

**Lỗi peer authentication chỉ ảnh hưởng khi dùng `sudo -u postgres`**. Ứng dụng sẽ dùng password authentication qua TCP/IP, không bị ảnh hưởng.

#### Kiểm tra file .env đã đúng chưa

```bash
cd /var/www/asset-rmg/backend
cat .env
```

**Đảm bảo có:**
```env
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
```

#### Chạy Prisma migrate trực tiếp

```bash
cd /var/www/asset-rmg/backend

# Generate Prisma client
npx prisma generate

# Chạy migrations (sẽ dùng password từ .env)
npx prisma migrate deploy
```

**Prisma sẽ tự động dùng password từ DATABASE_URL trong .env**, không cần peer authentication.

---

### Cách 3: Test connection với PGPASSWORD

```bash
# Set password và test
PGPASSWORD=Hainguyen261097 psql -U asset_user -d asset_rmg_db -h localhost -c "SELECT current_database(), current_user;"
```

---

## 🔍 Kiểm tra pg_hba.conf hiện tại

```bash
# Xem cấu hình hiện tại
cat /etc/postgresql/*/main/pg_hba.conf | grep -v "^#" | grep -v "^$"
```

**Tìm dòng có:**
- `local   all   all   peer` → Cần sửa thành `md5`
- `host   all   all   127.0.0.1/32   md5` → Đã OK

---

## ✅ Khuyến nghị

**Nếu chỉ cần chạy Prisma migrate**: Không cần sửa pg_hba.conf, chỉ cần đảm bảo file `.env` đúng và chạy `npx prisma migrate deploy`. Prisma sẽ dùng password authentication qua TCP/IP.

**Nếu muốn test connection từ command line**: Sửa pg_hba.conf như Cách 1.

---

## 📝 Sau khi fix

```bash
cd /var/www/asset-rmg/backend

# 1. Kiểm tra .env
cat .env | grep DATABASE_URL

# 2. Generate Prisma
npx prisma generate

# 3. Migrate (sẽ dùng password từ .env)
npx prisma migrate deploy

# 4. Kiểm tra status
npx prisma migrate status
```

---

## 🐛 Troubleshooting

### Vẫn báo authentication failed khi chạy Prisma

**Kiểm tra:**
1. File `.env` có đúng format không
2. Password trong `.env` có đúng không
3. User `asset_user` có tồn tại không: `sudo -u postgres psql -c "\du"`

### Không tìm thấy pg_hba.conf

```bash
# Tìm file
find /etc -name pg_hba.conf 2>/dev/null
find /var/lib -name pg_hba.conf 2>/dev/null

# Hoặc kiểm tra PostgreSQL version
sudo -u postgres psql -c "SELECT version();"
```

---

## 💡 Lưu ý

- **Peer authentication** chỉ ảnh hưởng khi dùng Unix socket với `sudo -u postgres`
- **Password authentication** (md5) hoạt động qua TCP/IP (localhost:5432)
- **Prisma** luôn dùng TCP/IP với password, không bị ảnh hưởng bởi peer authentication
