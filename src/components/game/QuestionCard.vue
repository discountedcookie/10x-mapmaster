<script setup lang="ts">
import { computed } from 'vue'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

interface Props {
  question: string
  questionNumber: number
  totalQuestions: number
  candidatesCount: number
  confidence?: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  answer: [value: boolean]
}>()

const confidencePercent = computed(() => {
  if (props.confidence === undefined) return
  return Math.round(props.confidence * 100)
})

const confidenceColor = computed(() => {
  if (!props.confidence) return 'text-muted-foreground'
  if (props.confidence >= 0.7) return 'text-green-600'
  if (props.confidence >= 0.4) return 'text-yellow-600'
  return 'text-red-600'
})
</script>

<template>
  <Card class="w-full max-w-2xl">
    <CardHeader>
      <CardDescription>Question {{ questionNumber }} of {{ totalQuestions }}</CardDescription>
      <CardTitle class="text-2xl">
        {{ question }}
      </CardTitle>
    </CardHeader>
    <CardContent class="space-y-2">
      <p class="text-sm text-muted-foreground">
        {{ candidatesCount }} possible {{ candidatesCount === 1 ? 'place' : 'places' }} remaining
      </p>
      <p
        v-if="confidencePercent !== undefined"
        class="text-sm"
        :class="confidenceColor"
      >
        Top match confidence: {{ confidencePercent }}%
      </p>
    </CardContent>
    <CardFooter class="flex gap-4">
      <Button
        class="flex-1"
        size="lg"
        @click="emit('answer', true)"
      >
        Yes
      </Button>
      <Button
        class="flex-1"
        size="lg"
        variant="outline"
        @click="emit('answer', false)"
      >
        No
      </Button>
    </CardFooter>
  </Card>
</template>
