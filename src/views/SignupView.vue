<script setup lang="ts">
import { ref } from 'vue'
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

const formSchema = toTypedSchema(z.object({
  email: z.string().email(t('auth.validation.invalid_email')),
  password: z.string().min(6, t('auth.validation.password_min_length', { length: 6 })),
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: t('auth.validation.passwords_do_not_match'),
  path: ['confirmPassword'],
}))

const form = useForm({
  validationSchema: formSchema,
})

const onSubmit = form.handleSubmit(async (values) => {
  try {
    loading.value = true
    await authStore.signUpWithEmail(values.email, values.password)

    // Redirect to login with success message, preserving redirect parameter
    const redirectParam = route.query.redirect ? `&redirect=${route.query.redirect}` : ''
    router.push(`/login?registered=true${redirectParam}`)
  }
  catch (error) {
    console.error('Signup error:', error)
    const errorMessage = error instanceof Error ? error.message : t('auth.toast.create_account_failed_generic')

    // Handle specific error cases
    if (errorMessage.includes('already registered')) {
      toast.error(t('auth.toast.account_exists_title'), {
        description: t('auth.toast.account_exists_body'),
      })
    }
    else if (errorMessage.includes('Password should be')) {
      toast.error(t('auth.toast.weak_password_title'), {
        description: errorMessage,
      })
    }
    else {
      toast.error(t('auth.toast.sign_up_failed_title'), {
        description: errorMessage,
      })
    }
  }
  finally {
    loading.value = false
  }
})

function goToLogin() {
  // Preserve redirect parameter when navigating to login
  const query = route.query.redirect ? { redirect: route.query.redirect } : {}
  router.push({ path: '/login', query })
}
</script>

<template>
  <!-- Blurred backdrop overlay -->
  <div class="absolute inset-0 backdrop-blur-md bg-black/30 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <Card class="w-full max-w-md mx-4 bg-background/95 shadow-2xl">
        <CardHeader class="space-y-1">
          <CardTitle class="text-2xl font-bold">
            {{ t('auth.signup_title') }}
          </CardTitle>
          <CardDescription>
            {{ t('auth.signup_description') }}
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
                <FormLabel>{{ t('auth.confirm_password') }}</FormLabel>
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
              {{ loading ? t('auth.creating_account') : t('auth.signup_button') }}
            </Button>
            <div class="text-sm text-center text-muted-foreground">
              {{ t('auth.have_account') }}
              <button
                type="button"
                class="text-primary underline-offset-4 hover:underline font-medium"
                @click="goToLogin"
              >
                {{ t('auth.login_button') }}
              </button>
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  </div>
</template>
