import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth'

import './style.css'
import 'maplibre-gl/dist/maplibre-gl.css'

async function initializeApp() {
    const app = createApp(App)

    app.use(createPinia())
    app.use(router)

    // Initialize auth before mounting
    const authStore = useAuthStore()
    await authStore.initialize()

    app.mount('#app')
}

initializeApp()
