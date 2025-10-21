<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
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

/** Navigation items */
const navItems = [
  { id: 'home', label: 'Home', path: '/' },
  { id: 'game', label: 'Game', path: '/game' },
  { id: 'statistics', label: 'Statistics', path: '/statistics' },
]

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

/** Check if nav item is active */
function isActive(path: string) {
  return route.path === path
}

/** Navigate to route */
function navigateTo(path: string) {
  // Prevent navigation if requires auth and not authenticated
  if (path === '/game' && !authStore.isAuthenticated) {
    router.push('/login')
    return
  }
  router.push(path)
}

/** Sign out handler */
async function handleSignOut() {
  try {
    await authStore.signOut()
    toast.success('Signed out successfully')
    router.push('/')
  }
  catch (error) {
    console.error('Sign out failed:', error)
    toast.error('Failed to sign out', {
      description: 'Please try again.',
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
    <div class="bg-white/80 dark:bg-gray-900/80 backdrop-blur-md shadow-lg rounded-full px-4 py-2 flex items-center gap-3">
      <!-- Logo -->
      <div class="flex items-center gap-2">
        <Icon
          icon="radix-icons:globe"
          class="h-5 w-5 text-primary"
        />
        <span class="font-bold text-base hidden sm:inline">10x-mapmaster</span>
      </div>

      <!-- Navigation Links -->
      <div class="flex items-center gap-1">
        <Button
          v-for="item in navItems"
          :key="item.id"
          :variant="isActive(item.path) ? 'default' : 'ghost'"
          size="sm"
          class="rounded-full h-8"
          @click="navigateTo(item.path)"
        >
          {{ item.label }}
        </Button>
      </div>

      <!-- User Menu / Actions -->
      <div class="flex items-center">
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <Button
              variant="ghost"
              size="icon"
              class="rounded-full h-8 w-8"
            >
              <Icon
                v-if="!authStore.isAuthenticated"
                icon="radix-icons:hamburger-menu"
                class="h-4 w-4"
              />
              <Avatar
                v-else
                class="h-7 w-7"
              >
                <AvatarFallback class="bg-primary text-primary-foreground text-xs font-semibold">
                  {{ userInitials }}
                </AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent
            align="end"
            class="w-56"
          >
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

            <!-- Theme Toggle -->
            <DropdownMenuLabel class="text-xs font-normal text-muted-foreground">
              Theme
            </DropdownMenuLabel>
            <DropdownMenuItem @click="setLight">
              <Icon
                icon="radix-icons:sun"
                class="mr-2 h-4 w-4"
              />
              Light
            </DropdownMenuItem>
            <DropdownMenuItem @click="setDark">
              <Icon
                icon="radix-icons:moon"
                class="mr-2 h-4 w-4"
              />
              Dark
            </DropdownMenuItem>
            <DropdownMenuItem @click="setAuto">
              <Icon
                icon="radix-icons:desktop"
                class="mr-2 h-4 w-4"
              />
              System
            </DropdownMenuItem>

            <DropdownMenuSeparator />

            <!-- Auth Actions -->
            <DropdownMenuItem
              v-if="authStore.isAuthenticated"
              @click="handleSignOut"
            >
              <Icon
                icon="radix-icons:exit"
                class="mr-2 h-4 w-4"
              />
              Sign Out
            </DropdownMenuItem>
            <DropdownMenuItem
              v-else
              @click="handleLogin"
            >
              <Icon
                icon="radix-icons:enter"
                class="mr-2 h-4 w-4"
              />
              Login
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>
  </nav>
</template>
