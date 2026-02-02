# 📤 Hướng dẫn Push Code lên GitHub

## Bước 1: Khởi tạo Git Repository (nếu chưa có)

```bash
cd d:\IT-LIST-RMG
git init
git branch -M main
```

## Bước 2: Thêm Remote Repository

```bash
git remote add origin https://github.com/HaiNguyen26/asset_RMG.git
```

Nếu đã có remote, xóa và thêm lại:
```bash
git remote remove origin
git remote add origin https://github.com/HaiNguyen26/asset_RMG.git
```

## Bước 3: Add và Commit

```bash
git add .
git commit -m "Initial commit: Asset RMG Management System"
```

## Bước 4: Push lên GitHub

```bash
git push -u origin main
```

Nếu gặp lỗi, thử force push (cẩn thận!):
```bash
git push -u origin main --force
```

## Bước 5: Kiểm tra

Truy cập: https://github.com/HaiNguyen26/asset_RMG để xem code đã được push.

---

## 🔄 Push Updates sau này

```bash
git add .
git commit -m "Update: mô tả thay đổi"
git push origin main
```
