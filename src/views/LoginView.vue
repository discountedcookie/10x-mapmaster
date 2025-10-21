<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import * as z from 'zod'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const loading = ref(false)

// Check for registration success message
onMounted(() => {
  if (route.query.registered === 'true') {
    toast.success('Account created!', {
      description: 'Please check your email to verify your account before signing in.',
      duration: 6000,
    })
  }
})

const formSchema = toTypedSchema(z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
}))

const form = useForm({
  validationSchema: formSchema,
})

const onSubmit = form.handleSubmit(async (values) => {
  try {
    loading.value = true
    await authStore.signInWithEmail(values.email, values.password)
    toast.success('Welcome back!', {
      description: 'You\'ve successfully signed in.',
    })
    router.push('/game')
  }
  catch (error) {
    console.error('Login error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Failed to sign in'

    // Handle specific error cases
    if (errorMessage.includes('Email not confirmed')) {
      toast.error('Email not verified', {
        description: 'Please check your email and click the verification link before signing in.',
        duration: 6000,
      })
    }
    else if (errorMessage.includes('Invalid login credentials')) {
      toast.error('Invalid credentials', {
        description: 'Please check your email and password and try again.',
      })
    }
    else {
      toast.error('Sign in failed', {
        description: errorMessage,
      })
    }
  }
  finally {
    loading.value = false
  }
})

function goToSignup() {
  router.push('/signup')
}
</script>

<template>
  <!-- Blurred backdrop overlay -->
  <div class="absolute inset-0 backdrop-blur-md bg-black/30 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <Card class="w-full max-w-md mx-4 bg-background/95 shadow-2xl">
        <CardHeader class="space-y-1">
          <CardTitle class="text-2xl font-bold">
            Sign in
          </CardTitle>
          <CardDescription>
            Enter your email and password to access your account
          </CardDescription>
        </CardHeader>
        <form @submit="onSubmit">
          <CardContent class="space-y-4">
            <FormField
              v-slot="{ componentField }"
              name="email"
            >
              <FormItem>
                <FormLabel>Email</FormLabel>
                <FormControl>
                  <Input
                    type="email"
                    placeholder="you@example.com"
                    v-bind="componentField"
                    autocomplete="email"
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            </FormField>

            <FormField
              v-slot="{ componentField }"
              name="password"
            >
              <FormItem>
                <FormLabel>Password</FormLabel>
                <FormControl>
                  <Input
                    type="password"
                    placeholder="••••••••"
                    v-bind="componentField"
                    autocomplete="current-password"
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            </FormField>
          </CardContent>
          <CardFooter class="flex flex-col space-y-4">
            <Button
              type="submit"
              class="w-full"
              :disabled="loading"
            >
              {{ loading ? 'Signing in...' : 'Sign In' }}
            </Button>
            <div class="text-sm text-center text-muted-foreground">
              Don't have an account?
              <button
                type="button"
                class="text-primary underline-offset-4 hover:underline font-medium"
                @click="goToSignup"
              >
                Sign up
              </button>
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  </div>
</template>
