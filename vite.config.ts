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
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Vendor libraries
          vendor: ['vue', 'pinia'],

          // Map libraries (heavy)
          maps: ['@indoorequal/vue-maplibre-gl', 'maplibre-gl'],

          // UI libraries
          ui: ['reka-ui', 'lucide-vue-next', 'clsx', 'tailwind-merge'],

          // Auth and database
          supabase: ['@supabase/supabase-js'],

          // External APIs
          apis: ['nominatim-ts'],

          // Form validation
          validation: ['@vee-validate/zod', 'vee-validate', 'zod'],
        },
      },
    },
    chunkSizeWarningLimit: 1000,
  },
  optimizeDeps: {
    include: ['vue', 'pinia', '@supabase/supabase-js', '@indoorequal/vue-maplibre-gl'],
  },
})
