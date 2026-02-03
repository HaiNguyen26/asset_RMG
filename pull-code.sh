#!/bin/bash
# Script tự động pull code từ GitHub

cd /var/www/asset-rmg

echo "📥 Pulling code từ GitHub..."
git pull origin main

echo "✅ Hoàn thành!"
