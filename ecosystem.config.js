// Load environment variables from .env file
require('dotenv').config({ path: require('path').join(__dirname, 'backend', '.env') });

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
        DATABASE_URL: process.env.DATABASE_URL,
        JWT_SECRET: process.env.JWT_SECRET,
      },
      error_file: '/var/log/pm2/asset-rmg-error.log',
      out_file: '/var/log/pm2/asset-rmg-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
}
