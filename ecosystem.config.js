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
        PORT: 4001,
        DATABASE_URL: 'postgresql://asset_user:Hainguyen261097@localhost:5432/asset_rmg_db',
        JWT_SECRET: 'your_jwt_secret_key_change_in_production_min_32_chars_please_change_this',
      },
      error_file: '/var/log/pm2/asset-rmg-error.log',
      out_file: '/var/log/pm2/asset-rmg-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
}
