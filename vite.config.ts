import path from 'node:path'
import process from 'node:process'

import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
// import vueDevTools from 'vite-plugin-vue-devtools'

export default defineConfig({
  plugins: [
    vue(),
    // vueDevTools(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // Use root path for local dev and CI tests, GitHub Pages path only for deployment
  base: process.env.GITHUB_PAGES ? '/10x-mapmaster/' : '/',
})
