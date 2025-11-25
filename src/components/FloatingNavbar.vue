<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { Icon } from '@iconify/vue'
import { useAuthStore } from '@/stores/auth'
import { useTheme } from '@/composables/useTheme'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { toast } from 'vue-sonner'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const { setLight, setDark, setAuto } = useTheme()
const { t, locale } = useI18n()

/** Available languages */
const availableLanguages = [
  { code: 'en', name: 'English', icon: '🇬🇧' },
  { code: 'es', name: 'Español', icon: '🇪🇸' },
  { code: 'pl', name: 'Polski', icon: '🇵🇱' },
]

/** Switch language */
function setLanguage(lang: string) {
  locale.value = lang
  localStorage.setItem('preferred-language', lang)
}

/** User initials for avatar */
const userInitials = computed(() => {
  if (!authStore.user?.email) return '?'
  const parts = authStore.user.email.split('@')[0]?.split('.') || []
  if (parts.length >= 2 && parts[0] && parts[1]) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase()
  }
  return authStore.user.email[0]?.toUpperCase() || '?'
})

/** User display name */
const userDisplayName = computed(() => {
  return authStore.user?.email?.split('@')[0] || 'User'
})

/** Sign out handler */
async function handleSignOut() {
  try {
    await authStore.signOut()
    toast.success(t('auth.toast.signed_out_success'))
    router.push('/')
  } catch (error) {
    console.error('Sign out failed:', error)
    toast.error(t('auth.toast.sign_out_failed_title'), {
      description: t('auth.toast.sign_out_failed_body'),
    })
  }
}

/** Handle login navigation */
function handleLogin() {
  router.push('/login')
}
</script>

<template>
  <nav class="fixed top-0 left-0 right-0 z-50 px-4 py-3 flex justify-center">
    <div
      class="bg-white/80 dark:bg-gray-900/80 backdrop-blur-md shadow-lg rounded-full px-4 py-2 flex items-center gap-3"
    >
      <!-- Logo -->
      <div class="flex items-center gap-2 cursor-pointer" @click="router.push('/')">
        <Icon icon="radix-icons:globe" class="h-5 w-5 text-primary" />
        <span class="font-bold text-base hidden sm:inline">{{ t('home.title') }}</span>
      </div>

      <!-- Theme, Language, and User Menus -->
      <div class="flex items-center gap-1">
        <!-- Theme Dropdown -->
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <Button
              variant="ghost"
              size="icon"
              class="rounded-full h-8 w-8"
              :title="t('theme.toggle_theme')"
            >
              <Icon icon="radix-icons:moon" class="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="w-48">
            <DropdownMenuLabel class="text-xs font-normal text-muted-foreground">
              {{ t('theme.title') }}
            </DropdownMenuLabel>
            <DropdownMenuItem @click="setLight">
              <Icon icon="radix-icons:sun" class="mr-2 h-4 w-4" />
              {{ t('theme.light') }}
            </DropdownMenuItem>
            <DropdownMenuItem @click="setDark">
              <Icon icon="radix-icons:moon" class="mr-2 h-4 w-4" />
              {{ t('theme.dark') }}
            </DropdownMenuItem>
            <DropdownMenuItem @click="setAuto">
              <Icon icon="radix-icons:desktop" class="mr-2 h-4 w-4" />
              {{ t('theme.system') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        <!-- Language Dropdown -->
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <Button
              variant="ghost"
              size="icon"
              class="rounded-full h-8 w-8"
              :title="t('language.title')"
            >
              <Icon icon="radix-icons:globe" class="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="w-48">
            <DropdownMenuLabel class="text-xs font-normal text-muted-foreground">
              {{ t('language.title') }}
            </DropdownMenuLabel>
            <DropdownMenuItem
              v-for="lang in availableLanguages"
              :key="lang.code"
              :class="{ 'bg-accent': locale === lang.code }"
              @click="setLanguage(lang.code)"
            >
              <span class="mr-2">{{ lang.icon }}</span>
              {{ lang.name }}
              <Icon v-if="locale === lang.code" icon="radix-icons:check" class="ml-auto h-4 w-4" />
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        <!-- User Dropdown -->
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <Button variant="ghost" size="icon" class="rounded-full h-8 w-8">
              <Icon v-if="!authStore.isAuthenticated" icon="radix-icons:person" class="h-4 w-4" />
              <Avatar v-else class="h-7 w-7">
                <AvatarFallback class="bg-primary text-primary-foreground text-xs font-semibold">
                  {{ userInitials }}
                </AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="w-56">
            <!-- User info (when logged in) -->
            <template v-if="authStore.isAuthenticated">
              <DropdownMenuLabel>
                <div class="flex flex-col space-y-1">
                  <p class="text-sm font-medium leading-none">
                    {{ userDisplayName }}
                  </p>
                  <p class="text-xs leading-none text-muted-foreground">
                    {{ authStore.user?.email }}
                  </p>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
            </template>

            <!-- Auth Actions -->
            <DropdownMenuItem v-if="authStore.isAuthenticated" @click="handleSignOut">
              <Icon icon="radix-icons:exit" class="mr-2 h-4 w-4" />
              {{ t('nav.logout') }}
            </DropdownMenuItem>
            <DropdownMenuItem v-else @click="handleLogin">
              <Icon icon="radix-icons:enter" class="mr-2 h-4 w-4" />
              {{ t('nav.login') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>
  </nav>
</template>
