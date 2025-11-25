<script setup lang="ts">
import { computed } from 'vue'
import { Card } from '@/components/ui/card'

interface Properties {
  gameState: import('@/stores/game').GameState
}

const properties = defineProps<Properties>()

const history = computed(() => {
  const messages = properties.gameState.messages
  const historyItems: { question: string; answer: string; confidence?: number }[] = []

  for (let index = 0; index < messages.length; index++) {
    if (messages[index]?.type === 'question') {
      const question = messages[index]?.text || ''
      const answerMessage = index + 1 < messages.length ? messages[index + 1] : null
      if (answerMessage && answerMessage.type === 'answer') {
        historyItems.push({
          question,
          answer: answerMessage!.text || '',
          confidence: answerMessage!.metadata?.confidence,
        })
      }
    }
  }

  return historyItems
})
</script>

<template>
  <Card class="p-4">
    <h4 class="text-sm font-medium mb-3">Question History</h4>

    <div class="max-h-64 overflow-auto">
      <div class="space-y-2">
        <div v-for="(item, index) in history" :key="index" class="text-sm p-2 rounded border">
          <div class="font-medium">Q{{ index + 1 }}: {{ item.question }}</div>
          <div class="text-muted-foreground">A: {{ item.answer }}</div>
          <div v-if="item.confidence" class="text-xs text-muted-foreground">
            Confidence: {{ Math.round(item.confidence * 100) }}%
          </div>
        </div>

        <div v-if="history.length === 0" class="text-xs text-muted-foreground text-center py-4">
          No questions yet
        </div>
      </div>
    </div>
  </Card>
</template>
