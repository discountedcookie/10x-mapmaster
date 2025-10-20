import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const session = ref<Session | null>(null)
  const loading = ref(true)

  const isAuthenticated = computed(() => !!user.value)

  async function initialize() {
    try {
      loading.value = true
      const { data } = await supabase.auth.getSession()
      session.value = data.session
      user.value = data.session?.user ?? null

      // Listen for auth changes
      supabase.auth.onAuthStateChange((_event, newSession) => {
        session.value = newSession
        user.value = newSession?.user ?? null
      })
    }
    finally {
      loading.value = false
    }
  }

  async function signInWithEmail(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (error)
      throw error
    return data
  }

  async function signUpWithEmail(email: string, password: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    })
    if (error)
      throw error
    return data
  }

  async function signOut() {
    const { error } = await supabase.auth.signOut()
    if (error)
      throw error
    user.value = null
    session.value = null
  }

  return {
    user,
    session,
    loading,
    isAuthenticated,
    initialize,
    signInWithEmail,
    signUpWithEmail,
    signOut,
  }
})
