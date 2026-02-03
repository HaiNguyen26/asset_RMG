# 🔧 Fix Git Pull Error - Local Changes

## 🚨 Lỗi

```
error: Your local changes to the following files would be overwritten by merge:
DELETE_DEPARTMENTS.sh
Please commit your changes or stash them before you merge.
```

## ✅ Giải Pháp

### Cách 1: Commit Local Changes (Khuyến nghị)

```bash
cd /var/www/asset-rmg

# Xem thay đổi
git status

# Xem diff (nếu muốn)
git diff DELETE_DEPARTMENTS.sh

# Commit local changes
git add DELETE_DEPARTMENTS.sh
git commit -m "Local changes to DELETE_DEPARTMENTS.sh"

# Pull lại
git pull origin main
```

### Cách 2: Stash Local Changes (Tạm thời lưu lại)

```bash
cd /var/www/asset-rmg

# Stash local changes
git stash

# Pull code mới
git pull origin main

# Nếu muốn lấy lại local changes sau
git stash pop
```

### Cách 3: Discard Local Changes (Xóa local changes)

⚠️ **Cẩn thận**: Cách này sẽ **XÓA** local changes của bạn!

```bash
cd /var/www/asset-rmg

# Xem thay đổi trước khi xóa
git diff DELETE_DEPARTMENTS.sh

# Xóa local changes
git checkout -- DELETE_DEPARTMENTS.sh

# Pull lại
git pull origin main
```

### Cách 4: Force Pull (Ghi đè local changes)

⚠️ **Cẩn thận**: Cách này sẽ **GHI ĐÈ** local changes bằng code từ GitHub!

```bash
cd /var/www/asset-rmg

# Reset về trạng thái của remote
git fetch origin
git reset --hard origin/main

# Pull lại
git pull origin main
```

## 📋 Quick Commands

### Nếu muốn giữ local changes:
```bash
cd /var/www/asset-rmg && git add DELETE_DEPARTMENTS.sh && git commit -m "Local changes" && git pull origin main
```

### Nếu muốn bỏ local changes:
```bash
cd /var/www/asset-rmg && git checkout -- DELETE_DEPARTMENTS.sh && git pull origin main
```

### Nếu muốn stash:
```bash
cd /var/www/asset-rmg && git stash && git pull origin main
```
