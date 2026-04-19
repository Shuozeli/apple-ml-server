module.exports = {
  apps: [
    {
      name: 'apple-ml-server',
      script: '.build/release/apple-ml-server',
      cwd: '/Users/chenxiyuan/projects/apple-ml-server',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 50051,
        RUST_LOG: 'info',
      },
      error_file: '/tmp/apple-ml-server.err.log',
      out_file: '/tmp/apple-ml-server.out.log',
      time: true,
      // Auto-restart on crash
      autorestart: true,
      // Restart delay (ms)
      restart_delay: 4000,
      // Max restarts in given time period
      max_restarts: 10,
      min_uptime: 10000,
    },
  ],
};
