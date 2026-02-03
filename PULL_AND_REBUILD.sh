#!/bin/bash

# Script để pull code từ git và rebuild ứng dụng trên server

set -e

echo "🔄 Bắt đầu pull code và rebuild..."

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

echo "✅ Hoàn tất! Ứng dụng đã được cập nhật."
echo ""
echo "📋 Kiểm tra logs:"
echo "   pm2 logs asset-rmg-api --lines 50"
echo ""
echo "🌐 Truy cập: http://27.71.16.15/asset_rmg"
