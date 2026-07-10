import uni from '@dcloudio/vite-plugin-uni'

export default {
  plugins: [uni()],
  server: {
    port: 3000,
    host: '0.0.0.0'
  }
}
