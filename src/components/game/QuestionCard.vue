<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import ConfidenceBadge from '@/components/ConfidenceBadge.vue'

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

const { t } = useI18n()

/** Progress percentage (0-100) */
const progressPercent = computed(() => {
  return (props.questionNumber / props.totalQuestions) * 100
})
</script>

<template>
  <Card
    class="w-full max-w-2xl animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader>
      <div class="flex items-center justify-between mb-2">
        <CardDescription>{{ t('game.question_card.question_number', { current: questionNumber, total: totalQuestions }) }}</CardDescription>
        <Progress
          :model-value="progressPercent"
          class="w-32 h-2"
        />
      </div>
      <CardTitle class="text-2xl">
        {{ question }}
      </CardTitle>
    </CardHeader>
    <CardContent class="space-y-3">
      <p class="text-sm text-muted-foreground">
        {{ t('game.question_card.places_remaining', { count: candidatesCount }) }}
      </p>
      <div
        v-if="confidence !== undefined"
        class="flex items-center gap-2"
      >
        <span class="text-sm text-muted-foreground">{{ t('game.question_card.top_match') }}:</span>
        <ConfidenceBadge :confidence="confidence" />
      </div>
    </CardContent>
    <CardFooter class="flex gap-4">
      <Button
        class="flex-1 transition-playful"
        size="lg"
        @click="emit('answer', true)"
      >
        {{ t('game.yes') }}
      </Button>
      <Button
        class="flex-1 transition-playful"
        size="lg"
        variant="outline"
        @click="emit('answer', false)"
      >
        {{ t('game.no') }}
      </Button>
    </CardFooter>
  </Card>
</template>
