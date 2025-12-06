<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { CardContent } from '@/components/ui/card'

const { t } = useI18n({ useScope: 'global' })
</script>

<template>
   <CardContent class="py-8">
     <p class="text-center text-muted-foreground">{{ t('game.loading_game') }}</p>
   </CardContent>
</template>
