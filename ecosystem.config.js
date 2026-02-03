// Load environment variables from .env file
const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

// Try to load .env file
const envPath = path.join(__dirname, 'backend', '.env');
if (fs.existsSync(envPath)) {
  const envConfig = dotenv.config({ path: envPath });
  if (envConfig.error) {
    console.error('Error loading .env file:', envConfig.error);
  }
} else {
  console.warn('Warning: .env file not found at', envPath);
}

module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',
      script: './backend/dist/src/main.js',
      cwd: '/var/www/asset-rmg',
      // Uncomment và thay path nếu dùng NVM để chỉ định Node.js version cụ thể
      // interpreter: '/root/.nvm/versions/node/v20.18.0/bin/node',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: process.env.PORT || 4001,
        DATABASE_URL: process.env.DATABASE_URL || 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db',
        JWT_SECRET: process.env.JWT_SECRET || 'your_jwt_secret_key_change_in_production_min_32_chars_please_change_this',
      },
      error_file: '/var/log/pm2/asset-rmg-error.log',
      out_file: '/var/log/pm2/asset-rmg-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
}
