import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const API_TARGET = process.env.VITE_PROXY_TARGET ?? 'http://15.207.72.29';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // Proxy API calls server-side so the browser only ever talks same-origin.
    // This lets the dashboard be shared over a LAN IP or public tunnel without
    // tripping the hosted backend's CORS allowlist.
    proxy: {
      '/api': {
        target: API_TARGET,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
    // Allow the dashboard to be served from any tunnel/host header.
    allowedHosts: true,
  },
});
