# Merge branch Intern vào Main (dành cho Mentor/Admin)

Khi đã review và đồng ý với code của intern trên branch `intern`, thực hiện merge vào `main` như sau.

---

## Cách 1: Merge qua GitHub (khuyến nghị)

1. Mở: https://github.com/HaiNguyen26/asset_RMG
2. Vào **Pull requests** → **New pull request**
3. Chọn:
   - **base:** `main`
   - **compare:** `intern`
4. Bấm **Create pull request**, ghi mô tả (ví dụ: "Merge công việc intern - [mô tả]")
5. Review diff, sau đó bấm **Merge pull request** → **Confirm merge**
6. (Tùy chọn) Xóa branch `intern` trên GitHub nếu không dùng nữa, hoặc giữ để intern tiếp tục làm.

---

## Cách 2: Merge bằng lệnh (local)

```bash
cd d:\IT-LIST-RMG

# Đảm bảo main sạch và mới nhất
git checkout main
git pull origin main

# Merge branch intern vào main
git merge intern -m "Merge branch intern vào main"

# Đẩy main lên GitHub
git push origin main
```

Sau khi merge, intern có thể tiếp tục làm việc trên `intern`:

```bash
git checkout intern
git pull origin main   # lấy code mới từ main vào intern
# ... làm việc, commit, push origin intern
```

---

## Lưu ý

- Chỉ merge khi đã review và đồng ý với thay đổi.
- Nếu có conflict, xử lý conflict trên branch `intern` hoặc trong PR rồi mới merge.
- Có thể tạo nhiều PR nhỏ (từng task) thay vì merge toàn bộ một lần.
