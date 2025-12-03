import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Lazy load all view components for code splitting
const HomeView = () => import('@/views/HomeView.vue')
const GameView = () => import('@/views/GameView.vue')
const LoginView = () => import('@/views/LoginView.vue')
const SignupView = () => import('@/views/SignupView.vue')
const StatisticsView = () => import('@/views/StatisticsView.vue')
const PlaceView = () => import('@/views/PlaceView.vue')

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
  await authStore.whenReady()

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
