#!/bin/bash
# Script tự động chạy web app Asset RMG từ đầu đến cuối

set -e  # Dừng nếu có lỗi

echo "🚀 Bắt đầu chạy Web App Asset RMG"
echo "=================================="

# Màu sắc cho output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_PATH="/var/www/asset-rmg"
BACKEND_PATH="$PROJECT_PATH/backend"
FRONTEND_PATH="$PROJECT_PATH/frontend"
NGINX_CONFIG="/etc/nginx/sites-available/it-request-tracking"

# Kiểm tra đang ở đúng thư mục
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}❌ Không tìm thấy thư mục: $PROJECT_PATH${NC}"
    echo "   Vui lòng chạy script từ server hoặc kiểm tra đường dẫn"
    exit 1
fi

cd "$PROJECT_PATH"

# ============================================
# BƯỚC 1: Pull Code Mới Nhất
# ============================================
echo ""
echo -e "${YELLOW}📥 Bước 1: Pull code mới nhất từ GitHub...${NC}"
if git pull origin main; then
    echo -e "${GREEN}✅ Pull code thành công${NC}"
else
    echo -e "${YELLOW}⚠️  Git pull failed hoặc không có thay đổi${NC}"
fi

# ============================================
# BƯỚC 2: Setup Backend
# ============================================
echo ""
echo -e "${YELLOW}🔨 Bước 2: Setup Backend...${NC}"
cd "$BACKEND_PATH"

# Kiểm tra và tạo .env file
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  File .env không tồn tại, tạo file mới...${NC}"
    cat > .env << EOF
PORT=4001
DATABASE_URL=postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db
JWT_SECRET=your_jwt_secret_key_change_in_production_min_32_chars_please_change_this
NODE_ENV=production
EOF
    echo -e "${GREEN}✅ Đã tạo file .env${NC}"
else
    echo -e "${GREEN}✅ File .env đã tồn tại${NC}"
fi

# Cài đặt dependencies
echo "📦 Installing backend dependencies..."
if npm install; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ npm install failed${NC}"
    exit 1
fi

# Generate Prisma Client
echo "🔧 Generating Prisma Client..."
if npx prisma generate; then
    echo -e "${GREEN}✅ Prisma Client generated${NC}"
else
    echo -e "${RED}❌ Prisma generate failed${NC}"
    exit 1
fi

# Chạy migrations
echo "🗄️  Running database migrations..."
if npx prisma migrate deploy; then
    echo -e "${GREEN}✅ Migrations completed${NC}"
else
    echo -e "${YELLOW}⚠️  Migration failed hoặc không có migrations mới${NC}"
fi

# Build backend
echo "🏗️  Building backend..."
if npm run build; then
    echo -e "${GREEN}✅ Backend build thành công${NC}"
    
    # Kiểm tra file main.js
    if [ -f dist/main.js ]; then
        echo -e "${GREEN}✅ File dist/main.js tồn tại${NC}"
    else
        echo -e "${RED}❌ File dist/main.js không tồn tại sau khi build${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Backend build failed${NC}"
    exit 1
fi

# ============================================
# BƯỚC 3: Setup Frontend
# ============================================
echo ""
echo -e "${YELLOW}🎨 Bước 3: Setup Frontend...${NC}"
cd "$FRONTEND_PATH"

# Cài đặt dependencies
echo "📦 Installing frontend dependencies..."
if npm install; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ npm install failed${NC}"
    exit 1
fi

# Build frontend
echo "🏗️  Building frontend..."
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
if npm run build; then
    echo -e "${GREEN}✅ Frontend build thành công${NC}"
    
    # Kiểm tra file index.html
    if [ -f dist/index.html ]; then
        echo -e "${GREEN}✅ File dist/index.html tồn tại${NC}"
    else
        echo -e "${RED}❌ File dist/index.html không tồn tại sau khi build${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

# ============================================
# BƯỚC 4: Thêm Nginx Config (nếu chưa có)
# ============================================
echo ""
echo -e "${YELLOW}🌐 Bước 4: Kiểm tra Nginx Config...${NC}"

if sudo grep -q "location /asset_rmg" "$NGINX_CONFIG"; then
    echo -e "${GREEN}✅ Nginx config đã có sẵn${NC}"
else
    echo -e "${YELLOW}⚠️  Nginx config chưa có, đang thêm...${NC}"
    
    # Chạy script thêm config
    if [ -f "$PROJECT_PATH/add-nginx-config.sh" ]; then
        chmod +x "$PROJECT_PATH/add-nginx-config.sh"
        sudo "$PROJECT_PATH/add-nginx-config.sh"
    else
        echo -e "${RED}❌ Không tìm thấy script add-nginx-config.sh${NC}"
        echo -e "${YELLOW}   Vui lòng thêm config thủ công (xem ADD_NGINX_CONFIG.md)${NC}"
    fi
fi

# ============================================
# BƯỚC 5: Start/Restart PM2
# ============================================
echo ""
echo -e "${YELLOW}🔄 Bước 5: Start/Restart PM2...${NC}"
cd "$PROJECT_PATH"

# Dừng process cũ nếu có
if pm2 list | grep -q "asset-rmg-api"; then
    echo "🛑 Dừng process cũ..."
    pm2 delete asset-rmg-api 2>/dev/null || true
fi

# Start với ecosystem.config.js
echo "🚀 Starting PM2..."
if pm2 start ecosystem.config.js; then
    echo -e "${GREEN}✅ PM2 started successfully${NC}"
    
    # Lưu PM2 config
    pm2 save
    
    # Hiển thị status
    echo ""
    echo "📊 PM2 Status:"
    pm2 status | grep asset-rmg-api || echo "⚠️  Process không hiển thị"
    
    # Hiển thị logs (5 dòng cuối)
    echo ""
    echo "📝 Logs (5 dòng cuối):"
    pm2 logs asset-rmg-api --lines 5 --nostream || echo "⚠️  Chưa có logs"
else
    echo -e "${RED}❌ PM2 start failed${NC}"
    exit 1
fi

# ============================================
# BƯỚC 6: Reload Nginx
# ============================================
echo ""
echo -e "${YELLOW}🔄 Bước 6: Reload Nginx...${NC}"

if sudo nginx -t; then
    echo -e "${GREEN}✅ Nginx config hợp lệ${NC}"
    if sudo systemctl reload nginx; then
        echo -e "${GREEN}✅ Nginx reloaded${NC}"
    else
        echo -e "${RED}❌ Nginx reload failed${NC}"
    fi
else
    echo -e "${RED}❌ Nginx config không hợp lệ${NC}"
fi

# ============================================
# BƯỚC 7: Kiểm Tra Ứng Dụng
# ============================================
echo ""
echo -e "${YELLOW}🔍 Bước 7: Kiểm tra ứng dụng...${NC}"

# Kiểm tra PM2
echo "📊 PM2 Status:"
pm2 status

# Kiểm tra backend
echo ""
echo "🔌 Testing Backend API..."
if curl -s http://localhost:4001/api > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend đang chạy trên port 4001${NC}"
else
    echo -e "${YELLOW}⚠️  Backend chưa phản hồi (có thể đang khởi động)${NC}"
fi

# Kiểm tra frontend
echo ""
echo "📁 Checking Frontend files..."
if [ -f "$FRONTEND_PATH/dist/index.html" ]; then
    echo -e "${GREEN}✅ Frontend files tồn tại${NC}"
else
    echo -e "${RED}❌ Frontend files không tồn tại${NC}"
fi

# ============================================
# HOÀN THÀNH
# ============================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Hoàn thành! Web App đã được chạy${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "🌐 Truy cập ứng dụng:"
echo "   Frontend: http://27.71.16.15/asset_rmg"
echo "   Backend API: http://27.71.16.15/asset_rmg/api"
echo ""
echo "📊 Quản lý PM2:"
echo "   Xem status: pm2 status"
echo "   Xem logs: pm2 logs asset-rmg-api"
echo "   Restart: pm2 restart asset-rmg-api"
echo "   Stop: pm2 stop asset-rmg-api"
echo ""
