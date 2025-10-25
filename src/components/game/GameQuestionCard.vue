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
  topCandidates?: Array<{
    name: string
    confidence: number
  }>
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
    <CardContent class="space-y-4">
      <!-- Top 5 Candidates Table -->
      <div
        v-if="topCandidates && topCandidates.length > 0"
        class="space-y-2"
      >
        <h4 class="text-sm font-medium text-muted-foreground">
          {{ t('game.question_card.top_candidates') }}
        </h4>
        <div class="bg-muted/50 rounded-lg p-3 space-y-2">
          <div
            v-for="(candidate, index) in topCandidates.slice(0, 5)"
            :key="index"
            class="flex items-center justify-between text-sm"
          >
            <div class="flex items-center gap-2">
              <span class="w-5 h-5 rounded-full bg-primary/20 flex items-center justify-center text-xs font-medium">
                {{ index + 1 }}
              </span>
              <span class="truncate">{{ candidate.name }}</span>
            </div>
            <div class="flex items-center gap-2">
              <ConfidenceBadge :confidence="candidate.confidence" />
            </div>
          </div>
        </div>
      </div>

      <!-- Fallback: Simple count if no candidates data -->
      <div
        v-else
        class="text-sm text-muted-foreground"
      >
        {{ t('game.question_card.candidates_remaining', { count: candidatesCount }) }}
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
