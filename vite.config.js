import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Determine base path: Capacitor uses './' for local file loading,
// Vercel uses '/' for CDN/HTTP deployment
const isCapacitor = process.env.CAPACITOR === 'true'

export default defineConfig({
  plugins: [vue()],
  base: isCapacitor ? './' : '/',
  server: {
    port: 3000,
    open: true,
    host: '0.0.0.0'
  }
})
