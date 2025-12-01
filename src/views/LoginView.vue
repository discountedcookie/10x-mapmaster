<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

interface Properties {
  renderMode?: 'layers' | 'ui'
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const _properties = withDefaults(defineProps<Properties>(), {
  renderMode: 'ui',
})
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import * as z from 'zod'
import { toast } from 'vue-sonner'
import { useI18n } from 'vue-i18n'
import { logger } from '@/lib/logger'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'

const router = useRouter()
const route = useRoute()
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

const formSchema = toTypedSchema(
  z.object({
    email: z.string().email(t('auth.validation.invalid_email')),
    password: z.string().min(6, t('auth.validation.password_min_length', { length: 6 })),
  })
)

const form = useForm({
  validationSchema: formSchema,
})

const onSubmit = form.handleSubmit(async (values) => {
  try {
    loading.value = true
    const { error } = await supabase.auth.signInWithPassword({
      email: values.email,
      password: values.password,
    })

    if (error) {
      // Handle specific error cases
      if (error.message.includes('Email not confirmed')) {
        toast.error(t('auth.toast.email_not_verified_title'), {
          description: t('auth.toast.email_not_verified_body'),
          duration: 6000,
        })
      } else if (error.message.includes('Invalid login credentials')) {
        toast.error(t('auth.toast.invalid_credentials_title'), {
          description: t('auth.toast.invalid_credentials_body'),
        })
      } else {
        toast.error(t('auth.toast.sign_in_failed_title'), {
          description: error.message,
        })
      }
      return
    }

    toast.success(t('auth.toast.welcome_back_title'), {
      description: t('auth.toast.welcome_back_body'),
    })

    // Redirect to the intended destination or default to game
    const redirectPath = (route.query.redirect as string) || '/game'
    router.push(redirectPath)
  } catch (error) {
    logger.error('Login error:', error)
    toast.error(t('auth.toast.sign_in_failed_title'), {
      description: t('auth.toast.sign_in_failed_generic'),
    })
  } finally {
    loading.value = false
  }
})

async function signInWithGitHub() {
  try {
    loading.value = true
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'github',
      options: {
        redirectTo: `${globalThis.location.origin}${import.meta.env.BASE_URL}game`,
      },
    })

    if (error) {
      toast.error(t('auth.toast.sign_in_failed_title'), {
        description: error.message,
      })
      loading.value = false
    }
    // OAuth will redirect, so no need to handle success here
  } catch (error) {
    logger.error('GitHub login error:', error)
    toast.error(t('auth.toast.sign_in_failed_title'), {
      description: t('auth.toast.oauth_failed_generic'),
    })
    loading.value = false
  }
}

function goToSignup() {
  router.push('/signup')
}
</script>

<template>
  <!-- No map layers for auth views -->
  <template v-if="renderMode === 'layers'" />

  <!-- UI - Blurred backdrop overlay -->
  <div
    v-else
    class="absolute inset-0 backdrop-blur-md bg-black/30 flex items-center justify-center pointer-events-none"
  >
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
            <FormField v-slot="{ componentField }" name="email">
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

            <FormField v-slot="{ componentField }" name="password">
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
            <Button type="submit" class="w-full" :disabled="loading">
              {{ loading ? t('auth.logging_in') : t('auth.login_button') }}
            </Button>

            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t" />
              </div>
              <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-background px-2 text-muted-foreground">
                  {{ t('auth.or_continue_with') }}
                </span>
              </div>
            </div>

            <Button
              type="button"
              variant="outline"
              class="w-full"
              :disabled="loading"
              @click="signInWithGitHub"
            >
              <svg class="mr-2 h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                <path
                  d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"
                />
              </svg>
              GitHub
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
