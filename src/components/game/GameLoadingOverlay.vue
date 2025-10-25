<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { Card, CardContent } from '@/components/ui/card'

const { t } = useI18n()
</script>

<template>
  <div
    class="absolute inset-0 flex flex-col items-center justify-center bg-black/60 backdrop-blur-sm pointer-events-auto z-50"
  >
    <Card class="max-w-md mx-4">
      <CardContent class="pt-6 pb-6 flex flex-col items-center gap-4">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" />
        <div class="text-center space-y-1">
          <p class="font-semibold text-lg">
            {{ t('game.loading_overlay.analyzing_description') }}
          </p>
          <p class="text-sm text-muted-foreground">
            {{ t('game.loading_overlay.finding_places') }}
          </p>
        </div>
      </CardContent>
    </Card>
  </div>
</template>