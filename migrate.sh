#!/bin/bash
# Script tự động chạy database migrations

cd /var/www/asset-rmg/backend

echo "🗄️  Running database migrations..."
npx prisma generate
npx prisma migrate deploy

echo "✅ Migrations completed!"
