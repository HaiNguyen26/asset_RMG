#!/bin/bash
# Fix Git pull conflict - xử lý local changes

echo "🔧 Fix Git pull conflict..."
echo "============================"

# 1. Kiểm tra status
echo ""
echo "1️⃣  Kiểm tra Git status:"
git status

# 2. Xem diff của file conflict
echo ""
echo "2️⃣  Xem thay đổi trong CHECK_APP_STATUS.sh:"
if [ -f "CHECK_APP_STATUS.sh" ]; then
    echo "--- Local changes ---"
    git diff CHECK_APP_STATUS.sh | head -30
    echo ""
    echo "--- Remote changes (nếu có) ---"
    git diff origin/main -- CHECK_APP_STATUS.sh | head -30 || echo "Không có remote changes"
else
    echo "⚠️  File không tồn tại"
fi

# 3. Hỏi user muốn làm gì
echo ""
echo "3️⃣  Chọn cách xử lý:"
echo "   [1] Stash local changes (giữ lại để sau)"
echo "   [2] Commit local changes (giữ lại và commit)"
echo "   [3] Discard local changes (xóa thay đổi local)"
echo ""
read -p "Chọn (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "📦 Stashing local changes..."
        git stash push -m "Stash before pull $(date +%Y%m%d_%H%M%S)"
        echo "✅ Đã stash"
        echo ""
        echo "🔄 Pulling code..."
        git pull origin main
        if [ $? -eq 0 ]; then
            echo "✅ Pull thành công!"
            echo ""
            echo "💡 Để xem lại thay đổi đã stash:"
            echo "   git stash list"
            echo "   git stash show -p stash@{0}"
            echo ""
            echo "💡 Để apply lại thay đổi:"
            echo "   git stash pop"
        fi
        ;;
    2)
        echo ""
        echo "💾 Committing local changes..."
        git add CHECK_APP_STATUS.sh
        git commit -m "Update CHECK_APP_STATUS.sh before pull"
        echo "✅ Đã commit"
        echo ""
        echo "🔄 Pulling code..."
        git pull origin main
        if [ $? -eq 0 ]; then
            echo "✅ Pull thành công!"
        else
            echo "⚠️  Có thể có merge conflict, cần resolve thủ công"
        fi
        ;;
    3)
        echo ""
        echo "⚠️  Xác nhận: Bạn có chắc muốn XÓA thay đổi local?"
        read -p "Nhập 'yes' để xác nhận: " confirm
        if [ "$confirm" = "yes" ]; then
            echo "🗑️  Discarding local changes..."
            git checkout -- CHECK_APP_STATUS.sh
            echo "✅ Đã xóa thay đổi local"
            echo ""
            echo "🔄 Pulling code..."
            git pull origin main
            if [ $? -eq 0 ]; then
                echo "✅ Pull thành công!"
            fi
        else
            echo "❌ Đã hủy"
        fi
        ;;
    *)
        echo "❌ Lựa chọn không hợp lệ"
        exit 1
        ;;
esac

echo ""
echo "✅ Hoàn thành!"
