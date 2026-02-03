#!/bin/bash
# Fix Git divergent branches issue

cd /var/www/asset-rmg

echo "🔧 Fixing Git divergent branches..."
echo "===================================="

# 1. Xem trạng thái hiện tại
echo ""
echo "1️⃣  Git status:"
git status

# 2. Xem log để hiểu divergence
echo ""
echo "2️⃣  Recent commits:"
git log --oneline --graph --all -10

# 3. Cấu hình Git pull strategy
echo ""
echo "3️⃣  Configuring Git pull strategy..."
git config pull.rebase false  # Use merge strategy

# 4. Pull với merge
echo ""
echo "4️⃣  Pulling with merge strategy..."
git pull origin main --no-edit

# 5. Kiểm tra kết quả
echo ""
echo "5️⃣  Git status sau khi pull:"
git status

echo ""
echo "✅ Hoàn thành!"
echo ""
echo "💡 Nếu vẫn có conflict, giải quyết conflict rồi:"
echo "   git add ."
echo "   git commit"
echo "   git push origin main"
