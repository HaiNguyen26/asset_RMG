# 🔧 Fix: Missing DATABASE_URL Error

## ❌ Lỗi hiện tại

```
Error: The `datasource.url` property is required in your Prisma config file 
when using `prisma migrate deploy`.
```

## ✅ Giải pháp: Tạo file .env

### Bước 1: Tạo file .env trong backend

```bash
cd /var/www/asset-rmg/backend

# Tạo file .env
nano .env
```

### Bước 2: Nhập nội dung vào file .env

**Nhập các dòng sau (thay các giá trị phù hợp):**

```env
PORT=4001
DATABASE_URL=postgresql://asset_user:your_password@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_here
NODE_ENV=production
```

**Giải thích:**
- `PORT=4001`: Port backend
- `DATABASE_URL`: Thay `your_password` bằng password bạn đã đặt khi tạo database user
- `JWT_SECRET`: Đặt một chuỗi bí mật dài ít nhất 32 ký tự
- `NODE_ENV=production`: Môi trường production

**Ví dụ cụ thể:**

Nếu bạn đã tạo:
- Database: `asset_rmg_db`
- User: `asset_user`
- Password: `MySecurePass123!`

Thì `DATABASE_URL` sẽ là:
```env
DATABASE_URL=postgresql://asset_user:MySecurePass123!@localhost:5432/asset_rmg_db
```

### Bước 3: Lưu file

Trong nano:
1. Nhấn `Ctrl + X` để thoát
2. Nhấn `Y` để xác nhận lưu
3. Nhấn `Enter` để xác nhận tên file

### Bước 4: Kiểm tra file .env đã được tạo

```bash
# Xem nội dung file (ẩn password)
cat .env | grep -v PASSWORD

# Hoặc xem toàn bộ (cẩn thận - sẽ hiển thị password)
cat .env
```

### Bước 5: Chạy lại Prisma migrate

```bash
# Generate Prisma client
npx prisma generate

# Chạy migrations
npx prisma migrate deploy

# Kiểm tra status
npx prisma migrate status
```

---

## 🔍 Kiểm tra Database Connection

### Kiểm tra database đã được tạo chưa

```bash
# Vào PostgreSQL
sudo -u postgres psql

# Kiểm tra database
\l
# Tìm database `asset_rmg_db` trong danh sách

# Kiểm tra user
\du
# Tìm user `asset_user` trong danh sách

# Thoát
\q
```

### Test connection

```bash
cd /var/www/asset-rmg/backend

# Test connection với Prisma
npx prisma db pull
# Hoặc
npx prisma studio
# (Sẽ mở browser để xem database)
```

---

## 🐛 Troubleshooting

### Lỗi: "password authentication failed"

**Nguyên nhân**: Password trong `.env` không đúng

**Giải pháp**:
```bash
# Kiểm tra password trong .env
cat .env | grep DATABASE_URL

# Test password bằng cách connect trực tiếp
sudo -u postgres psql -U asset_user -d asset_rmg_db
# Nhập password khi được hỏi

# Nếu sai, sửa lại trong .env
nano .env
```

### Lỗi: "database does not exist"

**Nguyên nhân**: Database chưa được tạo

**Giải pháp**:
```bash
sudo -u postgres psql

# Tạo database
CREATE DATABASE asset_rmg_db;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

\q
```

### Lỗi: "role does not exist"

**Nguyên nhân**: User chưa được tạo

**Giải pháp**:
```bash
sudo -u postgres psql

# Tạo user
CREATE USER asset_user WITH PASSWORD 'your_password';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE asset_rmg_db TO asset_user;

\c asset_rmg_db
GRANT ALL ON SCHEMA public TO asset_user;

\q
```

---

## 📝 Checklist

- [ ] File `.env` đã được tạo trong `/var/www/asset-rmg/backend/.env`
- [ ] `DATABASE_URL` đã được điền đúng format
- [ ] Password trong `DATABASE_URL` đúng với password của database user
- [ ] Database `asset_rmg_db` đã được tạo
- [ ] User `asset_user` đã được tạo và có quyền truy cập database
- [ ] `JWT_SECRET` đã được đặt (ít nhất 32 ký tự)
- [ ] `npx prisma generate` chạy thành công
- [ ] `npx prisma migrate deploy` chạy thành công

---

## 💡 Lưu ý bảo mật

- ⚠️ **KHÔNG** commit file `.env` lên Git (đã có trong `.gitignore`)
- ⚠️ **KHÔNG** chia sẻ file `.env` công khai
- ✅ Giữ file `.env` chỉ trên server
- ✅ Backup file `.env` ở nơi an toàn

---

## ✅ Sau khi fix xong

Tiếp tục các bước setup:

```bash
cd /var/www/asset-rmg/backend

# 1. Generate Prisma (nếu chưa)
npx prisma generate

# 2. Migrate database
npx prisma migrate deploy

# 3. Seed data (tùy chọn)
npx prisma db seed

# 4. Build backend
npm run build

# 5. Start với PM2
cd /var/www/asset-rmg
pm2 start ecosystem.config.js
```
