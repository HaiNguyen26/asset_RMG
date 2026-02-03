# 🔍 Kiểm tra và Pull Migrations

## ❌ Lỗi hiện tại

Bạn đang ở trong `/var/www/asset-rmg/backend` và chạy:
```bash
ls -la backend/prisma/migrations/
```

**Lỗi**: "No such file or directory" vì bạn đã ở trong `backend/` rồi.

## ✅ Giải pháp

### Bước 1: Pull migrations từ GitHub

```bash
# Về thư mục root của project
cd /var/www/asset-rmg

# Pull migrations mới
git pull origin main
```

### Bước 2: Kiểm tra migrations đã được pull

```bash
# Kiểm tra từ root project
ls -la backend/prisma/migrations/

# Hoặc nếu đang ở trong backend/
cd /var/www/asset-rmg/backend
ls -la prisma/migrations/
```

**Kết quả mong đợi**: Bạn sẽ thấy các thư mục:
- `20260202080556_init/`
- `20260202085339_add_users_and_employees_code/`
- `20260202111016_add_repair_history_and_policies/`
- `20260202120000_add_password_and_branch_to_user/`
- `migration_lock.toml`

### Bước 3: Chạy migrations

```bash
cd /var/www/asset-rmg/backend

# Deploy migrations
npx prisma migrate deploy

# Kiểm tra status
npx prisma migrate status
```

---

## 🔍 Nếu migrations vẫn không có sau khi pull

### Kiểm tra Git status

```bash
cd /var/www/asset-rmg

# Xem Git status
git status

# Xem các file đã thay đổi
git log --oneline -5

# Pull lại
git pull origin main --force
```

### Kiểm tra .gitignore

```bash
# Kiểm tra migrations có bị ignore không
cat .gitignore | grep migrations

# Nếu có, sửa lại
nano .gitignore
# Xóa hoặc comment dòng: **/prisma/migrations/
```

### Pull migrations thủ công

```bash
cd /var/www/asset-rmg

# Xem các file migrations trên GitHub
git ls-tree -r HEAD --name-only | grep migrations

# Pull lại
git pull origin main
```

---

## ✅ Sau khi có migrations

```bash
cd /var/www/asset-rmg/backend

# 1. Deploy migrations
npx prisma migrate deploy

# 2. Generate Prisma client
npx prisma generate

# 3. Seed data (tùy chọn)
npx prisma db seed

# 4. Build
npm run build
```

---

## 📝 Lưu ý về đường dẫn

- **Từ `/var/www/asset-rmg`**: Dùng `backend/prisma/migrations/`
- **Từ `/var/www/asset-rmg/backend`**: Dùng `prisma/migrations/` (không có `backend/`)
