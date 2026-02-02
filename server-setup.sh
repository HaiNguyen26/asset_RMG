#!/bin/bash

# Server Setup Script for Asset RMG
# Run this script on the server (27.71.16.15) as root

set -e

echo "🚀 Setting up Asset RMG on server..."

# Configuration
PROJECT_NAME="asset-rmg"
PROJECT_PATH="/var/www/${PROJECT_NAME}"
BACKEND_PORT="4001"
DB_NAME="asset_rmg_db"
DB_USER="asset_user"
DB_PASSWORD="change_this_password_in_production"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}📦 Step 1: Installing dependencies...${NC}"

# Update system
apt-get update

# Install Node.js 18 if not installed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install -g pm2
    pm2 startup
fi

# Install PostgreSQL if not installed
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL..."
    apt-get install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"

echo -e "${YELLOW}🗄️ Step 2: Setting up database...${NC}"

# Create database and user
sudo -u postgres psql << EOF
-- Create database
CREATE DATABASE ${DB_NAME};

-- Create user
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};

-- Connect to database and grant schema privileges
\c ${DB_NAME}
GRANT ALL ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};

\q
EOF

echo -e "${GREEN}✅ Database created${NC}"

echo -e "${YELLOW}📥 Step 3: Cloning repository...${NC}"

# Create project directory
mkdir -p ${PROJECT_PATH}

# Clone or update repository
if [ -d "${PROJECT_PATH}/.git" ]; then
    echo "Repository exists, pulling updates..."
    cd ${PROJECT_PATH}
    git pull origin main || echo "Git pull failed, continuing..."
else
    echo "Cloning repository..."
    cd /var/www
    git clone https://github.com/HaiNguyen26/asset_RMG.git ${PROJECT_NAME}
fi

echo -e "${GREEN}✅ Repository cloned${NC}"

echo -e "${YELLOW}⚙️ Step 4: Setting up backend...${NC}"

cd ${PROJECT_PATH}/backend

# Install dependencies
npm install

# Create .env file if not exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
PORT=${BACKEND_PORT}
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
EOF
    echo -e "${YELLOW}⚠️  Please edit .env file with your actual values!${NC}"
fi

# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate deploy || echo "Migration may have failed, check manually"

# Build backend
npm run build

echo -e "${GREEN}✅ Backend setup completed${NC}"

echo -e "${YELLOW}🎨 Step 5: Setting up frontend...${NC}"

cd ${PROJECT_PATH}/frontend

# Install dependencies
npm install

# Build frontend
export VITE_API_URL="http://27.71.16.15/asset_rmg/api"
npm run build

echo -e "${GREEN}✅ Frontend setup completed${NC}"

echo -e "${YELLOW}🔄 Step 6: Setting up PM2...${NC}"

cd ${PROJECT_PATH}

# Start with PM2
pm2 delete ${PROJECT_NAME}-api 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

echo -e "${GREEN}✅ PM2 setup completed${NC}"

echo -e "${YELLOW}🌐 Step 7: Configuring Nginx...${NC}"

# Find active Nginx config file
NGINX_CONFIG_FILE=""
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    NGINX_CONFIG_FILE="/etc/nginx/sites-enabled/default"
elif [ -f "/etc/nginx/sites-enabled/it-request-tracking" ]; then
    NGINX_CONFIG_FILE="/etc/nginx/sites-enabled/it-request-tracking"
else
    # Find first enabled site
    NGINX_CONFIG_FILE=$(ls /etc/nginx/sites-enabled/* 2>/dev/null | head -n 1)
fi

if [ -z "$NGINX_CONFIG_FILE" ] || [ ! -f "$NGINX_CONFIG_FILE" ]; then
    echo -e "${RED}⚠️  Could not find active Nginx config file${NC}"
    echo -e "${YELLOW}Please manually add the following to your Nginx config:${NC}"
    cat << 'NGINX_MANUAL'
# Asset RMG - Backend API
location /asset_rmg/api {
    proxy_pass http://localhost:4001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Asset RMG - Frontend
location /asset_rmg {
    alias /var/www/asset-rmg/frontend/dist;
    index index.html;
    try_files $uri $uri/ /asset_rmg/index.html;
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_MANUAL
else
    echo "Found Nginx config: $NGINX_CONFIG_FILE"
    
    # Check if config already exists
    if grep -q "location /asset_rmg" "$NGINX_CONFIG_FILE"; then
        echo -e "${YELLOW}Asset RMG config already exists in Nginx config${NC}"
    else
        echo -e "${YELLOW}⚠️  Please manually add the following location blocks to: $NGINX_CONFIG_FILE${NC}"
        echo -e "${YELLOW}Add them inside the 'server { ... }' block:${NC}"
        echo ""
        cat << 'NGINX_BLOCKS'
# Asset RMG - Backend API
location /asset_rmg/api {
    proxy_pass http://localhost:4001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}

# Asset RMG - Frontend
location /asset_rmg {
    alias /var/www/asset-rmg/frontend/dist;
    index index.html;
    try_files $uri $uri/ /asset_rmg/index.html;
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_BLOCKS
        echo ""
        echo -e "${YELLOW}After adding, run: nginx -t && systemctl reload nginx${NC}"
    fi
fi

echo -e "${GREEN}🎉 Setup completed!${NC}"
echo -e "${GREEN}🌐 Access your app at: http://27.71.16.15/asset_rmg${NC}"
echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
echo -e "   1. Edit ${PROJECT_PATH}/backend/.env with your actual values"
echo -e "   2. Run 'npx prisma db seed' if you need seed data"
echo -e "   3. Check PM2 status: pm2 status"
echo -e "   4. Check logs: pm2 logs ${PROJECT_NAME}-api"
