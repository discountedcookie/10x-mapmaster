<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { Icon } from '@iconify/vue'
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const router = useRouter()
const authStore = useAuthStore()
const { t } = useI18n()

const handleGetStarted = () => {
  if (authStore.isAuthenticated) {
    router.push('/game')
  }
  else {
    router.push('/login')
  }
}
</script>

<template>
  <Card
    class="w-full max-w-md animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader class="bg-gradient-playful text-white rounded-t-xl">
      <CardTitle class="text-4xl font-bold flex items-center gap-3">
        <Icon
          icon="radix-icons:globe"
          class="h-10 w-10"
        />
        <span>{{ t('home.title') }}</span>
      </CardTitle>
      <CardDescription class="text-base text-white/90 mt-2">
        {{ t('home.tagline') }}
      </CardDescription>
    </CardHeader>
    <CardContent class="pt-6">
      <Button
        size="lg"
        class="w-full transition-playful shadow-playful-sm hover:shadow-playful-lg"
        @click="handleGetStarted"
      >
        <Icon
          icon="radix-icons:rocket"
          class="h-5 w-5 mr-2"
        />
        {{ t('home.get_started') }}
      </Button>
    </CardContent>
  </Card>
</template>
