import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import GameView from '@/views/GameView.vue'
import LoginView from '@/views/LoginView.vue'
import SignupView from '@/views/SignupView.vue'
import StatisticsView from '@/views/StatisticsView.vue'
import PlaceView from '@/views/PlaceView.vue'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/places/:id',
      name: 'place',
      component: PlaceView,
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { requiresGuest: true },
    },
    {
      path: '/signup',
      name: 'signup',
      component: SignupView,
      meta: { requiresGuest: true },
    },
    {
      path: '/game/:sessionId',
      name: 'game',
      component: GameView,
      // Allow anonymous access for now
    },
    {
      path: '/statistics',
      name: 'statistics',
      component: StatisticsView,
      meta: { requiresAuth: true },
    },
  ],
})

// Navigation guard to protect routes
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Wait for auth to be initialized before checking authentication
  while (authStore.loading) {
    await new Promise((resolve) => setTimeout(resolve, 50))
  }

  // Check if route requires authentication
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    // Save the intended destination to redirect back after login
    next({ path: '/login', query: { redirect: to.fullPath } })
    return
  }

  // Check if route requires guest (redirect authenticated users away from auth pages)
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next('/')
    return
  }

  next()
})

export default router
