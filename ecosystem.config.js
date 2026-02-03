// Load environment variables from .env file (if exists)
const path = require('path');
const fs = require('fs');

let DATABASE_URL = 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db';
let JWT_SECRET = 'your_jwt_secret_key_change_in_production_min_32_chars_please_change_this';
let PORT = 4001;

// Try to load from .env file
const envPath = path.join(__dirname, 'backend', '.env');
if (fs.existsSync(envPath)) {
  try {
    const envFile = fs.readFileSync(envPath, 'utf8');
    const envLines = envFile.split('\n');
    
    envLines.forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        if (key && valueParts.length > 0) {
          const value = valueParts.join('=').trim();
          if (key === 'DATABASE_URL') DATABASE_URL = value;
          if (key === 'JWT_SECRET') JWT_SECRET = value;
          if (key === 'PORT') PORT = parseInt(value) || 4001;
        }
      }
    });
    
    console.log('✅ Loaded .env file from:', envPath);
  } catch (error) {
    console.warn('⚠️  Could not read .env file, using defaults:', error.message);
  }
} else {
  console.warn('⚠️  .env file not found at:', envPath, '- using default values');
}

module.exports = {
  apps: [
    {
      name: 'asset-rmg-api',
      script: './backend/dist/src/main.js',
      cwd: '/var/www/asset-rmg',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: PORT,
        DATABASE_URL: DATABASE_URL,
        JWT_SECRET: JWT_SECRET,
      },
      error_file: '/var/log/pm2/asset-rmg-error.log',
      out_file: '/var/log/pm2/asset-rmg-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
}
