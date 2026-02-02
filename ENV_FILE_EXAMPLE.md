# 📝 File .env mẫu cho Server

## Nội dung file `.env` cần tạo

Tạo file tại: `/var/www/asset-rmg/backend/.env`

```env
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=rmg_asset_management_secret_key_2026_very_secure_32_chars_minimum
NODE_ENV=production
```

---

## Cách tạo trên server

```bash
cd /var/www/asset-rmg/backend

# Tạo file .env
cat > .env << 'EOF'
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=rmg_asset_management_secret_key_2026_very_secure_32_chars_minimum
NODE_ENV=production
EOF

# Kiểm tra file đã được tạo
cat .env
```

---

## Hoặc dùng nano

```bash
cd /var/www/asset-rmg/backend
nano .env
```

Copy-paste nội dung sau vào:

```
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=rmg_asset_management_secret_key_2026_very_secure_32_chars_minimum
NODE_ENV=production
```

Lưu: `Ctrl + X`, sau đó `Y`, sau đó `Enter`

---

## Sau khi tạo file .env

```bash
# Generate Prisma client
npx prisma generate

# Chạy migrations
npx prisma migrate deploy

# Kiểm tra status
npx prisma migrate status
```

---

## ⚠️ Lưu ý bảo mật

- File `.env` đã được thêm vào `.gitignore` - không commit lên Git
- Giữ file này chỉ trên server
- Không chia sẻ password công khai
