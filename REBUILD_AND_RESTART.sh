#!/bin/bash

# Script để rebuild và restart ứng dụng sau khi pull code mới

set -e

echo "🔄 Bắt đầu rebuild và restart ứng dụng..."

cd /var/www/asset-rmg

echo "📥 Pulling code mới từ GitHub..."
git pull origin main

echo "🔨 Building backend..."
cd backend
npm run build
cd ..

echo "🏗️  Building frontend..."
cd frontend
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build
cd ..

echo "🔄 Restarting PM2 process..."
pm2 restart asset-rmg-api

echo "✅ Hoàn tất! Kiểm tra logs:"
echo "   pm2 logs asset-rmg-api --lines 50"
