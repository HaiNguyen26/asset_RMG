# Quản Trị Tài Sản (Asset Management)

Ứng dụng quản lý tài sản với dashboard hiện đại, cấu trúc phân lớp rõ ràng, tối ưu cho dữ liệu lớn.

## Cấu trúc dự án

- **frontend/** — React 18 + Vite + Tailwind CSS + Lucide + Framer Motion
- **backend/** — NestJS + Prisma + PostgreSQL

## Yêu cầu

- Node.js 18+
- PostgreSQL (cho backend, khi chạy API thật)
- npm hoặc pnpm

## Quick Start - Chạy cả Frontend và Backend

### Bước 1: Cài đặt dependencies

```bash
npm run install:all
```

Lệnh này sẽ cài đặt dependencies cho cả root, frontend và backend.

### Bước 2: Setup Database (chỉ cần chạy 1 lần đầu)

```bash
cd backend
npm run db:setup
```

Lệnh này sẽ tự động:
- Tạo database `asset_management` (nếu chưa có)
- Chạy Prisma migration để tạo tables
- Seed dữ liệu mẫu

**Lưu ý:** Đảm bảo PostgreSQL server đang chạy trước khi chạy lệnh này.

### Bước 2.5: Tạo tài khoản IT Admin (nếu chưa có)

```bash
cd backend
npm run create-admin
```

Tài khoản IT Admin:
- **Mã nhân viên:** `IT`
- **Role:** ADMIN
- **Đăng nhập:** Nhập `IT` vào ô mã nhân viên

### Bước 3: Chạy cả Frontend và Backend (tự động mở trình duyệt)

```bash
npm run dev
```

Lệnh này sẽ:
- ✅ Chạy backend tại http://localhost:3000/api
- ✅ Chạy frontend tại http://localhost:5173
- ✅ **Tự động mở trình duyệt** khi frontend sẵn sàng

## Chạy riêng lẻ (nếu cần)

**Chỉ Frontend:**
```bash
cd frontend
npm run dev
```

**Chỉ Backend:**
```bash
cd backend
npm run start:dev
```

## Tính năng chính

- **Sidebar (256px):** Branding "QUẢN TRỊ TÀI SẢN", menu Laptop / Phụ kiện IT / Thiết bị Kỹ thuật (icon Laptop, Chuột, Cờ lê), mục active nền indigo, thẻ Admin phía dưới.
- **Header:** Tên mục tài sản + mô tả, nút "Thêm tài sản" (indigo, shadow).
- **Table View:** Thanh công cụ (tìm kiếm, lọc Trạng thái & Phòng ban), bảng dữ liệu với header in hoa đậm, status badge (Dự phòng / Đang sử dụng / Thanh lý / Bảo trì), hàng hover, action (Xem, Sửa, Cấp phát).
- **Detail View:** 2 cột (Thông tin Tài sản + Thông tin Sử dụng), icon mờ nền, nút Cấp phát / Thu hồi / Cập nhật sửa chữa, khối ghi chú quản trị màu xanh nhạt.

## Công nghệ

- **Frontend:** React 18+, Tailwind CSS, Lucide React, Framer Motion, React Router
- **Backend:** Node.js, NestJS, Prisma, PostgreSQL
- **Deploy (gợi ý):** Vercel/Netlify (frontend), Docker/Kubernetes (backend khi mở rộng)
