<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import * as z from 'zod'
import { toast } from 'vue-sonner'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const { t } = useI18n()

const loading = ref(false)

// Check for registration success message
onMounted(() => {
  if (route.query.registered === 'true') {
    toast.success(t('auth.toast.account_created_title'), {
      description: t('auth.toast.account_created_body'),
      duration: 6000,
    })
  }
})

const formSchema = toTypedSchema(z.object({
  email: z.string().email(t('auth.validation.invalid_email')),
  password: z.string().min(6, t('auth.validation.password_min_length', { length: 6 })),
}))

const form = useForm({
  validationSchema: formSchema,
})

const onSubmit = form.handleSubmit(async (values) => {
  try {
    loading.value = true
    await authStore.signInWithEmail(values.email, values.password)
    toast.success(t('auth.toast.welcome_back_title'), {
      description: t('auth.toast.welcome_back_body'),
    })
    // Redirect to the intended destination or default to game
    const redirectPath = (route.query.redirect as string) || '/game'
    router.push(redirectPath)
  }
  catch (error) {
    console.error('Login error:', error)
    const errorMessage = error instanceof Error ? error.message : t('auth.toast.sign_in_failed_generic')

    // Handle specific error cases
    if (errorMessage.includes('Email not confirmed')) {
      toast.error(t('auth.toast.email_not_verified_title'), {
        description: t('auth.toast.email_not_verified_body'),
        duration: 6000,
      })
    }
    else if (errorMessage.includes('Invalid login credentials')) {
      toast.error(t('auth.toast.invalid_credentials_title'), {
        description: t('auth.toast.invalid_credentials_body'),
      })
    }
    else {
      toast.error(t('auth.toast.sign_in_failed_title'), {
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
            {{ t('auth.login_title') }}
          </CardTitle>
          <CardDescription>
            {{ t('auth.login_description') }}
          </CardDescription>
        </CardHeader>
        <form @submit="onSubmit">
          <CardContent class="space-y-4">
            <FormField
              v-slot="{ componentField }"
              name="email"
            >
              <FormItem>
                <FormLabel>{{ t('auth.email') }}</FormLabel>
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
                <FormLabel>{{ t('auth.password') }}</FormLabel>
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
              {{ loading ? t('auth.logging_in') : t('auth.login_button') }}
            </Button>
            <div class="text-sm text-center text-muted-foreground">
              {{ t('auth.no_account') }}
              <button
                type="button"
                class="text-primary underline-offset-4 hover:underline font-medium"
                @click="goToSignup"
              >
                {{ t('auth.signup_button') }}
              </button>
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  </div>
</template>
