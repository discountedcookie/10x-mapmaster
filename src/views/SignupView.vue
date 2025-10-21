<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
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
const authStore = useAuthStore()

const loading = ref(false)

const formSchema = toTypedSchema(z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
}))

const form = useForm({
  validationSchema: formSchema,
})

const onSubmit = form.handleSubmit(async (values) => {
  try {
    loading.value = true
    await authStore.signUpWithEmail(values.email, values.password)

    // Redirect to login with success message
    router.push('/login?registered=true')
  }
  catch (error) {
    console.error('Signup error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Failed to create account'

    // Handle specific error cases
    if (errorMessage.includes('already registered')) {
      toast.error('Account exists', {
        description: 'An account with this email already exists. Please sign in instead.',
      })
    }
    else if (errorMessage.includes('Password should be')) {
      toast.error('Weak password', {
        description: errorMessage,
      })
    }
    else {
      toast.error('Sign up failed', {
        description: errorMessage,
      })
    }
  }
  finally {
    loading.value = false
  }
})

function goToLogin() {
  router.push('/login')
}
</script>

<template>
  <!-- Blurred backdrop overlay -->
  <div class="absolute inset-0 backdrop-blur-md bg-black/30 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <Card class="w-full max-w-md mx-4 bg-background/95 shadow-2xl">
        <CardHeader class="space-y-1">
          <CardTitle class="text-2xl font-bold">
            Create an account
          </CardTitle>
          <CardDescription>
            Enter your email and password to create your account. You'll need to verify your email before signing in.
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
                    autocomplete="new-password"
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            </FormField>

            <FormField
              v-slot="{ componentField }"
              name="confirmPassword"
            >
              <FormItem>
                <FormLabel>Confirm Password</FormLabel>
                <FormControl>
                  <Input
                    type="password"
                    placeholder="••••••••"
                    v-bind="componentField"
                    autocomplete="new-password"
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
              {{ loading ? 'Creating account...' : 'Create Account' }}
            </Button>
            <div class="text-sm text-center text-muted-foreground">
              Already have an account?
              <button
                type="button"
                class="text-primary underline-offset-4 hover:underline font-medium"
                @click="goToLogin"
              >
                Sign in
              </button>
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  </div>
</template>
