#!/bin/bash

# Deploy script for Asset RMG
# Server: 27.71.16.15
# Path: /asset_rmg

set -e

echo "🚀 Starting deployment..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="27.71.16.15"
SERVER_USER="root"
PROJECT_NAME="asset-rmg"
PROJECT_PATH="/var/www/${PROJECT_NAME}"
BACKEND_PORT="4001"
FRONTEND_BASE="/asset_rmg"

echo -e "${YELLOW}📦 Step 1: Building frontend...${NC}"
cd frontend
export VITE_API_URL="http://${SERVER_IP}${FRONTEND_BASE}/api"
npm run build
cd ..

echo -e "${YELLOW}📦 Step 2: Building backend...${NC}"
cd backend
npm run build
cd ..

echo -e "${GREEN}✅ Build completed!${NC}"
echo -e "${YELLOW}📤 Step 3: Pushing to GitHub...${NC}"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    git branch -M main
fi

# Add all files
git add .

# Check if there are changes
if git diff --staged --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    git commit -m "Deploy: $(date +'%Y-%m-%d %H:%M:%S')"
fi

# Push to GitHub
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/HaiNguyen26/asset_RMG.git
git push -u origin main --force

echo -e "${GREEN}✅ Code pushed to GitHub!${NC}"
echo -e "${YELLOW}📡 Step 4: Deploying to server...${NC}"

# SSH commands to deploy
ssh ${SERVER_USER}@${SERVER_IP} << EOF
set -e

echo "📥 Cloning/updating repository..."
if [ -d "${PROJECT_PATH}" ]; then
    cd ${PROJECT_PATH}
    git pull origin main || echo "Git pull failed, continuing..."
else
    mkdir -p ${PROJECT_PATH}
    cd ${PROJECT_PATH}
    git clone https://github.com/HaiNguyen26/asset_RMG.git .
fi

echo "📦 Installing dependencies..."
cd ${PROJECT_PATH}/backend
npm install --production

cd ${PROJECT_PATH}/frontend
npm install --production

echo "🔨 Building..."
cd ${PROJECT_PATH}/backend
npm run build

cd ${PROJECT_PATH}/frontend
export VITE_API_URL="http://${SERVER_IP}${FRONTEND_BASE}/api"
npm run build

echo "🗄️ Setting up database..."
cd ${PROJECT_PATH}/backend
npx prisma generate
npx prisma migrate deploy || echo "Migration may have failed, check manually"

echo "🔄 Restarting PM2..."
pm2 delete ${PROJECT_NAME}-api 2>/dev/null || true
cd ${PROJECT_PATH}/backend
pm2 start dist/main.js --name ${PROJECT_NAME}-api --update-env
pm2 save

echo "🌐 Reloading Nginx..."
systemctl reload nginx

echo "✅ Deployment completed!"
EOF

echo -e "${GREEN}🎉 Deployment finished!${NC}"
echo -e "${GREEN}🌐 Access your app at: http://${SERVER_IP}${FRONTEND_BASE}${NC}"
