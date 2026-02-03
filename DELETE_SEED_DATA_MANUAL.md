# 🗑️ Xóa Seed Data Từ Database

## 📋 Seed Data Bao Gồm

Dữ liệu seed được tạo bởi file `backend/prisma/seed.ts`:

1. **Departments:**
   - WAREHOUSE - Kho
   - TECH - Phòng Công nghệ
   - ADMIN - Phòng Hành chính
   - ACCOUNT - Phòng Kế toán

2. **Categories:**
   - laptop - Laptop
   - it_accessory - Phụ kiện IT
   - tech_equipment - Thiết bị Kỹ thuật

3. **Users:**
   - IT Admin (employeesCode: 'IT')

4. **Assets:** (đã được xóa khỏi seed, dùng Excel import)

## 🗑️ Cách Xóa Seed Data

### Cách 1: Dùng Script Tự Động (Khuyến nghị)

```bash
cd /var/www/asset-rmg

# Pull script mới
git pull origin main

# Cho phép script chạy
chmod +x DELETE_ALL_SEED_DATA.sh

# Chạy script
./DELETE_ALL_SEED_DATA.sh
```

Script sẽ xóa:
- ✅ Tất cả Departments
- ✅ Tất cả Categories
- ✅ Tất cả Users (trừ IT Admin)
- ✅ Tất cả Assets

### Cách 2: Xóa Thủ Công Qua PostgreSQL

```bash
# Kết nối vào database
sudo -u postgres psql -d asset_rmg_db

# Xóa theo thứ tự (quan trọng!)
DELETE FROM "Assignment";
DELETE FROM "assets";
DELETE FROM "users" WHERE employees_code != 'IT';
DELETE FROM "Department";
DELETE FROM "AssetCategory";

# Thoát
\q
```

### Cách 3: Xóa Từng Loại

#### Xóa Departments:

```bash
cd /var/www/asset-rmg
chmod +x DELETE_DEPARTMENTS.sh
./DELETE_DEPARTMENTS.sh
```

#### Xóa Categories:

```bash
cd /var/www/asset-rmg/backend

node -e "
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

prisma.assetCategory.deleteMany({}).then(result => {
  console.log('✅ Đã xóa', result.count, 'categories');
  prisma.\$disconnect();
  pool.end();
});
"
```

## ⚠️ Lưu Ý Quan Trọng

1. **Xóa Departments sẽ ảnh hưởng:**
   - Users thuộc departments đó → `departmentId = null`
   - Assets thuộc departments đó → `departmentId = null`

2. **Xóa Categories sẽ ảnh hưởng:**
   - Assets thuộc categories đó → **SẼ BỊ XÓA** (cascade delete)

3. **Thứ tự xóa quan trọng:**
   - Phải xóa Assets trước (có foreign key)
   - Sau đó mới xóa Departments và Categories

## 🔄 Nếu Muốn Chạy Lại Seed

```bash
cd /var/www/asset-rmg/backend

# Chạy lại seed (sẽ tạo lại dữ liệu)
npx prisma db seed
```

## 📝 Sửa File Seed.ts Để Không Tạo Seed Data Nữa

Nếu muốn không tạo seed data khi chạy `npx prisma db seed`:

1. Sửa file `backend/prisma/seed.ts`
2. Comment hoặc xóa các dòng tạo departments/categories
3. Nhưng **dữ liệu cũ vẫn còn trong database**, cần xóa thủ công

## ✅ Kiểm Tra Sau Khi Xóa

```bash
# Test API
curl http://localhost:4001/api/departments
curl http://localhost:4001/api/categories
curl http://localhost:4001/api/assets

# Nếu trả về [] → Đã xóa thành công
```
