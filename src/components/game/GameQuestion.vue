<script setup lang="ts">
import { Button } from '@/components/ui/button'

interface Props {
  question: string
  loading?: boolean
}

interface Emits {
  (e: 'answer', value: boolean): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()
</script>

<template>
  <div class="space-y-4">
    <p class="text-lg text-center">{{ question }}</p>

    <div class="flex gap-3">
      <Button class="flex-1" :disabled="loading" @click="emit('answer', true)"> Yes </Button>
      <Button class="flex-1" variant="outline" :disabled="loading" @click="emit('answer', false)">
        No
      </Button>
    </div>
  </div>
</template>
