<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

interface Props {
  questionCount: number
  maxQuestions: number
  candidatesCount: number
}

interface Emits {
  (e: 'resume'): void
  (e: 'startFresh'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
</script>

<template>
  <Card
    class="w-full animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader class="text-center space-y-3">
      <CardTitle class="text-3xl font-bold flex items-center justify-center gap-3">
        <Icon
          icon="radix-icons:question-mark-circled"
          class="h-10 w-10 text-primary"
        />
        Resume Game?
      </CardTitle>
      <CardDescription class="text-lg">
        You have an unfinished game session. Would you like to continue where you left off?
      </CardDescription>
    </CardHeader>
    <CardContent class="flex flex-col gap-3">
      <div class="text-sm text-muted-foreground text-center">
        <p>Questions asked: {{ questionCount }} / {{ maxQuestions }}</p>
        <p>Candidates remaining: {{ candidatesCount }}</p>
      </div>
      <Button
        size="lg"
        class="transition-playful"
        @click="emit('resume')"
      >
        <Icon
          icon="radix-icons:play"
          class="h-5 w-5 mr-2"
        />
        Resume Game
      </Button>
      <Button
        size="lg"
        variant="outline"
        class="transition-playful"
        @click="emit('startFresh')"
      >
        <Icon
          icon="radix-icons:reload"
          class="h-5 w-5 mr-2"
        />
        Start New Game
      </Button>
    </CardContent>
  </Card>
</template>
