<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'

interface Properties {
   guessText: string
   loading?: boolean
 }

 interface Emits {
   (e: 'answer', value: boolean): void
 }

 defineProps<Properties>()
 const emit = defineEmits<Emits>()
 const { t } = useI18n({ useScope: 'global' })
</script>

<template>
   <div class="space-y-4">
     <p class="text-lg text-center">{{ guessText }}</p>

     <div class="flex gap-3">
       <Button class="flex-1" :disabled="loading" @click="emit('answer', true)">
         {{ t('game.yes_correct') }}
       </Button>
       <Button class="flex-1" variant="outline" :disabled="loading" @click="emit('answer', false)">
         {{ t('game.no_try_again') }}
       </Button>
     </div>
   </div>
</template>
