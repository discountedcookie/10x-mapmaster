import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { logger } from '@/lib/logger'
import type { User, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User>()
  const session = ref<Session>()
  const loading = ref(true)

  // Promise-based ready state (resolves when auth initialization completes)
  let readyResolve: (() => void) | null = null
  let readyPromise: Promise<void> | null = null

  function whenReady(): Promise<void> {
    // If already initialized, resolve immediately
    if (!loading.value) {
      return Promise.resolve()
    }
    // Create promise if not exists (handles whenReady called before initialize)
    if (!readyPromise) {
      readyPromise = new Promise((resolve) => {
        readyResolve = resolve
      })
    }
    return readyPromise
  }

  // Computed
  const isAuthenticated = computed(() => !!user.value && !user.value.is_anonymous)
  const isAnonymous = computed(() => user.value?.is_anonymous ?? false)

  // Initialize auth and ensure anonymous session
  async function initialize() {
    try {
      loading.value = true
      const { data, error } = await supabase.auth.getSession()

      // Handle invalid refresh tokens gracefully
      if (error) {
        logger.warn('Session restoration failed', {
          error: error.message,
          code: 'AUTH_SESSION_RESTORATION_FAILED',
        })
        await supabase.auth.signOut()
      }

      // Create anonymous session if none exists
      if (!data.session) {
        logger.info('No session found, creating anonymous session')
        const { error: anonError } = await supabase.auth.signInAnonymously()
        if (anonError) {
          logger.error('Anonymous sign in failed', {
            error: anonError.message,
            code: 'AUTH_ANONYMOUS_FAILED',
          })
        }
      }

      // Listen for auth state changes
      supabase.auth.onAuthStateChange((_event, newSession) => {
        session.value = newSession ?? undefined
        user.value = newSession?.user
      })
    } finally {
      loading.value = false
      // Resolve the ready promise
      if (readyResolve) {
        readyResolve()
        readyResolve = null
      }
    }
  }

  // Sign out and create new anonymous session
  async function signOut() {
    await supabase.auth.signOut()
    user.value = undefined
    session.value = undefined

    // Create new anonymous session after sign out
    const { error } = await supabase.auth.signInAnonymously()
    if (error) {
      logger.error('Failed to create anonymous session after signout', {
        error: error.message,
      })
    }
  }

  return {
    user,
    session,
    loading,
    isAuthenticated,
    isAnonymous,
    initialize,
    signOut,
    whenReady,
  }
})
