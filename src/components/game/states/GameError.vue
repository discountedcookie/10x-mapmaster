<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { CardContent } from '@/components/ui/card'

interface Properties {
   error: string
 }

 defineProps<Properties>()
 const { t } = useI18n({ useScope: 'global' })
</script>

<template>
   <CardContent class="py-8">
     <p class="text-center text-destructive">{{ error }}</p>
     <p class="text-center text-muted-foreground text-sm mt-2">{{ t('game.redirecting_home') }}</p>
   </CardContent>
</template>
