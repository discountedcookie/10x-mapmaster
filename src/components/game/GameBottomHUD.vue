<script setup lang="ts">
import { ref, computed } from 'vue'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Separator } from '@/components/ui/separator'
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible'
import {
  CheckCircle,
  XCircle,
  Target,
  History,
  ChevronDown,
  ChevronUp,
  TrendingUp,
  TrendingDown,
} from 'lucide-vue-next'

interface ChatMessage {
  id: string
  role: 'system' | 'user'
  type: 'question' | 'guess' | 'answer' | 'message'
  text: string
  timestamp: Date
}

interface Props {
  currentQuestion: string
  questionCount: number
  maxQuestions?: number
  confidence: number
  threshold: number
  loading?: boolean
  history?: ChatMessage[]
  onAnswer?: (answer: boolean) => void
}

const props = withDefaults(defineProps<Props>(), {
  maxQuestions: 5,
  loading: false,
  history: () => [],
})

const emit = defineEmits<{
  answer: [value: boolean]
}>()

const showHistory = ref(false)

// Calculate progress percentage
const progressPercentage = computed(() => {
  return (props.confidence / props.threshold) * 100
})

// Format confidence as percentage
const confidencePercent = computed(() => {
  return Math.round(props.confidence * 100)
})

const thresholdPercent = computed(() => {
  return Math.round(props.threshold * 100)
})

// Get user messages from history (questions and answers)
const userHistory = computed(() => {
  return props.history.filter((msg) => msg.type === 'question' || msg.type === 'answer')
})

// Handle answer button click
const handleAnswer = (answer: boolean) => {
  if (!props.loading) {
    emit('answer', answer)
  }
}
</script>

<template>
  <Card
    class="fixed bottom-8 left-1/2 -translate-x-1/2 w-full max-w-3xl mx-4 bg-background/95 backdrop-blur-md shadow-2xl border-2 z-50"
  >
    <!-- Compact Header: Progress -->
    <div class="flex items-center justify-between p-4 border-b">
      <div class="flex items-center gap-3 flex-wrap">
        <Badge variant="outline" class="font-mono">
          Question {{ questionCount }}/{{ maxQuestions }}
        </Badge>
        <Separator orientation="vertical" class="h-4 hidden sm:block" />
        <div class="flex items-center gap-2 flex-1 min-w-0">
          <Target class="w-4 h-4 flex-shrink-0" />
          <Progress :model-value="progressPercentage" class="w-32 sm:w-40" />
          <span class="text-sm font-mono whitespace-nowrap">
            {{ confidencePercent }}%/{{ thresholdPercent }}%
          </span>
        </div>
      </div>
      <Collapsible v-model:open="showHistory">
        <CollapsibleTrigger as-child>
          <Button variant="ghost" size="sm" class="gap-2">
            <History class="w-4 h-4" />
            <span class="hidden sm:inline">Journey</span>
            <component :is="showHistory ? ChevronUp : ChevronDown" class="w-4 h-4" />
          </Button>
        </CollapsibleTrigger>
      </Collapsible>
    </div>

    <!-- History (Collapsible) -->
    <Collapsible v-model:open="showHistory">
      <CollapsibleContent class="p-4 bg-muted/50 border-b">
        <div v-if="userHistory.length > 0" class="space-y-3 text-sm max-h-64 overflow-y-auto">
          <div v-for="(msg, idx) in userHistory" :key="msg.id" class="space-y-2">
            <div class="flex items-center gap-2">
              <Badge variant="secondary" class="font-mono"
                >{{ msg.type === 'question' ? 'Q' : 'A' }}{{ idx + 1 }}</Badge
              >
              <span class="text-muted-foreground flex-1">{{ msg.text }}</span>
            </div>
          </div>
        </div>
        <div v-else class="text-center text-muted-foreground py-4 text-sm">
          No history yet. Answer questions to build your journey!
        </div>
      </CollapsibleContent>
    </Collapsible>

    <!-- Current Question -->
    <div class="p-6">
      <div class="text-center space-y-4">
        <p class="text-xl sm:text-2xl font-medium">
          {{ currentQuestion }}
        </p>

        <!-- Answer Buttons -->
        <div class="flex gap-4 justify-center pt-4 flex-wrap sm:flex-nowrap">
          <Button
            size="lg"
            class="w-full sm:w-40 text-lg gap-2"
            variant="default"
            :disabled="loading"
            @click="handleAnswer(true)"
          >
            <CheckCircle class="w-5 h-5" />
            YES
          </Button>
          <Button
            size="lg"
            class="w-full sm:w-40 text-lg gap-2"
            variant="outline"
            :disabled="loading"
            @click="handleAnswer(false)"
          >
            <XCircle class="w-5 h-5" />
            NO
          </Button>
        </div>

        <!-- Loading state -->
        <div
          v-if="loading"
          class="flex items-center justify-center gap-2 text-sm text-muted-foreground"
        >
          <div
            class="animate-spin rounded-full h-4 w-4 border-2 border-primary border-t-transparent"
          ></div>
          Analyzing answer...
        </div>
      </div>
    </div>
  </Card>
</template>
