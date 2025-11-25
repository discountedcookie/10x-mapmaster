<script setup lang="ts">
import { computed } from 'vue'
import { Progress } from '@/components/ui/progress'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'

interface Properties {
  gameState: import('@/stores/game').GameState
}

const props = defineProps<Properties>()

const confidencePercent = computed(() => Math.round(props.gameState.confidence * 100))
const thresholdPercent = computed(() => Math.round(props.gameState.threshold * 100))

const progress = computed(() => {
  const highest = props.gameState.confidence
  const threshold = props.gameState.threshold
  if (highest >= threshold) return 1
  const progress = (highest - 0.5) / (threshold - 0.5) // Scale from 0.5 to threshold
  return Math.max(0, Math.min(1, progress))
})

const progressColor = computed(() => {
  const p = progress.value
  if (p < 0.3) return 'bg-red-500'
  if (p < 0.7) return 'bg-yellow-500'
  return 'bg-green-500'
})

// Gap to 2nd place - assuming candidates are sorted
const gapToSecond = computed(() => {
  const candidates = props.gameState.candidates
  if (candidates.length < 2) return 0
  return (candidates[0]?.confidence ?? 0) - (candidates[1]?.confidence ?? 0)
})

const gapNeeded = 0.05 // TODO: from config

// Question progress
const questionProgress = computed(() => {
  const current = props.gameState.questionCount
  const max = 8
  return Math.min(current / max, 1)
})
</script>

<template>
  <Card class="p-4">
    <div class="space-y-2">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium">Confidence Meter</span>
        <Badge :class="progressColor"> {{ confidencePercent }}% / {{ thresholdPercent }}% </Badge>
      </div>

      <Progress :value="progress * 100" :class="progressColor" />

      <div class="text-xs text-muted-foreground space-y-1">
        <div>Gap to 2nd: {{ gapToSecond.toFixed(3) }} (need {{ gapNeeded }})</div>
        <div>Questions: {{ props.gameState.questionCount }}/8</div>
      </div>
    </div>
  </Card>
</template>
