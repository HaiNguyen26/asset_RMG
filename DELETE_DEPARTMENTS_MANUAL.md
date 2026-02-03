# 🗑️ Hướng Dẫn Xóa Departments Từ Database

## 📋 Giải Thích

Dữ liệu "WAREHOUSE-Kho", "TECH-Phòng Công nghệ", v.v. **KHÔNG phải** là mapping trong code, mà là **dữ liệu trong database PostgreSQL**.

API `/api/departments` đọc từ database qua Prisma, không phải từ code mapping.

## 🔍 Kiểm Tra Dữ Liệu Trong Database

```bash
cd /var/www/asset-rmg/backend

# Kết nối vào database
sudo -u postgres psql -d asset_rmg_db

# Xem tất cả departments
SELECT * FROM "Department";

# Thoát
\q
```

## 🗑️ Cách Xóa Departments

### Cách 1: Dùng Script Tự Động

```bash
cd /var/www/asset-rmg

# Pull script mới
git pull origin main

# Cho phép script chạy
chmod +x DELETE_DEPARTMENTS.sh

# Chạy script
./DELETE_DEPARTMENTS.sh
```

### Cách 2: Xóa Thủ Công Qua PostgreSQL

```bash
# Kết nối vào database
sudo -u postgres psql -d asset_rmg_db

# Xóa tất cả departments
DELETE FROM "Department";

# Hoặc xóa từng cái
DELETE FROM "Department" WHERE code = 'WAREHOUSE';
DELETE FROM "Department" WHERE code = 'TECH';
DELETE FROM "Department" WHERE code = 'ADMIN';
DELETE FROM "Department" WHERE code = 'ACCOUNT';

# Thoát
\q
```

### Cách 3: Xóa Qua Prisma Studio (GUI)

```bash
cd /var/www/asset-rmg/backend

# Mở Prisma Studio
npx prisma studio

# Truy cập: http://localhost:5555
# Xóa departments trong giao diện
```

## ⚠️ Lưu Ý Quan Trọng

1. **Xóa departments sẽ ảnh hưởng đến:**
   - Users đang thuộc departments đó (sẽ bị set `departmentId = null`)
   - Assets đang thuộc departments đó (sẽ bị set `departmentId = null`)

2. **Nếu muốn giữ lại dữ liệu:**
   - Chỉ cần không gọi API `/api/departments` nữa
   - Hoặc sửa code để filter/ẩn departments không muốn hiển thị

3. **Nếu muốn thay đổi dữ liệu:**
   - Sửa file `backend/prisma/seed.ts`
   - Xóa dữ liệu cũ
   - Chạy lại seed: `npx prisma db seed`

## 🔄 Nếu Muốn Chạy Lại Seed Với Dữ Liệu Mới

```bash
cd /var/www/asset-rmg/backend

# 1. Sửa file seed.ts (xóa hoặc comment các departments không muốn)

# 2. Xóa dữ liệu cũ (nếu cần)
# DELETE FROM "Department";

# 3. Chạy lại seed
npx prisma db seed
```

## 📝 Sửa File Seed.ts

Nếu muốn không tạo departments này nữa, sửa file `backend/prisma/seed.ts`:

```typescript
// Comment hoặc xóa các dòng này:
// const deptWarehouse = await prisma.department.upsert({
//   where: { code: 'WAREHOUSE' },
//   update: {},
//   create: { code: 'WAREHOUSE', name: 'Kho' },
// })
```

Sau đó chạy lại seed (nhưng dữ liệu cũ vẫn còn trong database, cần xóa thủ công).
