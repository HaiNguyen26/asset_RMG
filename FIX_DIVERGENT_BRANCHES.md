# 🔧 Fix Git Divergent Branches Error

## 🚨 Lỗi

```
fatal: Need to specify how to reconcile divergent branches.
```

## ✅ Giải Pháp

### Cách 1: Pull với Merge Strategy (Khuyến nghị)

```bash
cd /var/www/asset-rmg

# Cấu hình Git pull strategy
git config pull.rebase false

# Pull với merge
git pull origin main --no-edit
```

### Cách 2: Pull với Rebase Strategy

```bash
cd /var/www/asset-rmg

# Cấu hình Git pull strategy
git config pull.rebase true

# Pull với rebase
git pull origin main
```

### Cách 3: Force Pull (Ghi đè local)

⚠️ **Cẩn thận**: Cách này sẽ **GHI ĐÈ** local commits!

```bash
cd /var/www/asset-rmg

# Fetch latest
git fetch origin

# Reset về remote
git reset --hard origin/main

# Pull lại
git pull origin main
```

### Cách 4: Merge Manual

```bash
cd /var/www/asset-rmg

# Fetch latest
git fetch origin

# Merge manual
git merge origin/main

# Nếu có conflict, giải quyết rồi:
git add .
git commit
```

## 📋 Quick Commands

### Merge strategy (khuyến nghị):
```bash
cd /var/www/asset-rmg && git config pull.rebase false && git pull origin main --no-edit
```

### Rebase strategy:
```bash
cd /var/www/asset-rmg && git config pull.rebase true && git pull origin main
```

### Force pull (ghi đè local):
```bash
cd /var/www/asset-rmg && git fetch origin && git reset --hard origin/main && git pull origin main
```

## 🔍 Hiểu Về Divergent Branches

**Divergent branches** xảy ra khi:
- Local branch có commits mà remote không có
- Remote branch có commits mà local không có
- Git không biết cách merge tự động

**Giải pháp:**
- **Merge**: Tạo merge commit kết hợp cả 2 branches
- **Rebase**: Đặt local commits lên trên remote commits
- **Reset**: Ghi đè local bằng remote (mất local commits)

## 💡 Khuyến Nghị

Trên server, nên dùng **merge strategy** để giữ lại cả local và remote changes:

```bash
git config pull.rebase false
git pull origin main --no-edit
```
