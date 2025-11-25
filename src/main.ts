import { createApp } from 'vue'
import { createPinia } from 'pinia'
import VueMaplibreGl from '@indoorequal/vue-maplibre-gl'

import App from './App.vue'
import router from './router'
import i18n from './i18n'
import { useAuthStore } from '@/stores/auth'

import './style.css'
import 'maplibre-gl/dist/maplibre-gl.css'
// CSS is imported automatically by the library

async function initializeApp() {
  const app = createApp(App)

  app.use(createPinia())
  app.use(router)
  app.use(i18n)
  app.use(VueMaplibreGl)

  // Initialize auth before mounting
  const authStore = useAuthStore()
  await authStore.initialize()

  app.mount('#app')
}

initializeApp()
