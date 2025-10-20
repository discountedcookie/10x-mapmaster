<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

const authStore = useAuthStore()

const isSignUp = ref(false)
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref<string | undefined>(undefined)

async function handleSubmit() {
  if (!email.value || !password.value) {
    error.value = 'Please fill in all fields'
    return
  }

  try {
    loading.value = true
    error.value = undefined

    await (isSignUp.value ? authStore.signUpWithEmail(email.value, password.value) : authStore.signInWithEmail(email.value, password.value))
  }
  catch (error_) {
    error.value = error_ instanceof Error ? error_.message : 'Authentication failed'
  }
  finally {
    loading.value = false
  }
}

function toggleMode() {
  isSignUp.value = !isSignUp.value
  error.value = undefined
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
    <Card class="w-full max-w-md">
      <CardHeader>
        <CardTitle>{{ isSignUp ? 'Create Account' : 'Sign In' }}</CardTitle>
        <CardDescription>
          {{ isSignUp ? 'Sign up to save your game progress' : 'Sign in to continue playing' }}
        </CardDescription>
      </CardHeader>
      <form @submit.prevent="handleSubmit">
        <CardContent class="space-y-4">
          <div class="space-y-2">
            <label
              for="email"
              class="text-sm font-medium"
            >Email</label>
            <input
              id="email"
              v-model="email"
              type="email"
              required
              class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              placeholder="you@example.com"
            >
          </div>
          <div class="space-y-2">
            <label
              for="password"
              class="text-sm font-medium"
            >Password</label>
            <input
              id="password"
              v-model="password"
              type="password"
              required
              class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              placeholder="••••••••"
            >
          </div>
          <p
            v-if="error"
            class="text-sm text-destructive"
          >
            {{ error }}
          </p>
        </CardContent>
        <CardFooter class="flex flex-col space-y-4">
          <Button
            type="submit"
            class="w-full"
            :disabled="loading"
          >
            {{ loading ? 'Loading...' : (isSignUp ? 'Sign Up' : 'Sign In') }}
          </Button>
          <Button
            type="button"
            variant="ghost"
            class="w-full"
            @click="toggleMode"
          >
            {{ isSignUp ? 'Already have an account? Sign in' : 'Need an account? Sign up' }}
          </Button>
        </CardFooter>
      </form>
    </Card>
  </div>
</template>
