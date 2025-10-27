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
      const { data, error } = await supabase.auth.getSession()

      // Handle invalid refresh tokens gracefully
      if (error) {
        console.warn('Session restoration failed:', error.message)
        // Clear invalid session
        await supabase.auth.signOut()
        session.value = null
        user.value = null
      }
      else {
        session.value = data.session
        user.value = data.session?.user ?? null
      }

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
    if (error) {
      // Provide more specific error messages
      if (error.message.includes('Email not confirmed')) {
        throw new Error('Email not confirmed. Please check your email and click the verification link.')
      }
      if (error.message.includes('Invalid login credentials')) {
        throw new Error('Invalid login credentials. Please check your email and password.')
      }
      throw new Error(error.message || 'Failed to sign in. Please try again.')
    }
    return data
  }

  async function signUpWithEmail(email: string, password: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    })
    if (error) {
      // Provide more specific error messages
      if (error.message.includes('already registered')) {
        throw new Error('An account with this email already exists. Please sign in instead.')
      }
      if (error.message.includes('Password')) {
        throw new Error(error.message)
      }
      throw new Error(error.message || 'Failed to create account. Please try again.')
    }
    return data
  }

  async function signInWithGitHub() {
    // Use Vite's base URL to handle both dev (/) and production (/10x-mapmaster/)
    const baseUrl = import.meta.env.BASE_URL
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'github',
      options: {
        redirectTo: `${window.location.origin}${baseUrl}game`,
      },
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
    signInWithGitHub,
    signOut,
  }
})
