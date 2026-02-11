# Hướng dẫn làm việc cho Intern

## Quy tắc quan trọng

- **Không được commit/push trực tiếp lên branch `main`.**
- Làm việc **chỉ trên branch `intern`**.
- Khi hoàn thành task, push lên branch `intern` và báo để review/merge vào `main`.

---

## Bước 1: Clone repo và vào branch intern

```bash
# Clone (nếu chưa có repo)
git clone https://github.com/HaiNguyen26/asset_RMG.git
cd asset_RMG

# Chuyển sang branch intern
git checkout intern

# Cập nhật branch intern mới nhất (sau này mỗi lần bắt đầu làm việc)
git pull origin intern
```

---

## Bước 2: Làm việc hàng ngày

```bash
# Đảm bảo đang ở branch intern
git branch
# Phải thấy: * intern

# Sau khi sửa code, commit và push lên branch intern
git add .
git commit -m "Mô tả ngắn thay đổi"
git push origin intern
```

---

## Bước 3: Khi cần merge vào main (chỉ Mentor/Admin thực hiện)

**Intern không tự merge.** Khi bạn đồng ý với thay đổi:

1. Trên GitHub: vào repo → **Pull requests** → **New pull request**
2. Base: `main` ← Compare: `intern`
3. Tạo PR, review code, sau đó **Merge pull request**
4. Hoặc merge bằng lệnh (trên máy Mentor):

```bash
git checkout main
git pull origin main
git merge intern
git push origin main
```

---

## Tóm tắt

| Việc | Branch | Ai làm |
|------|--------|--------|
| Làm task, commit, push | `intern` | Intern |
| Review & merge vào `main` | `main` | Mentor/Admin |
| Deploy / chạy production | `main` | Mentor/Admin |

**Repo:** https://github.com/HaiNguyen26/asset_RMG  
**Branch làm việc:** `intern`
