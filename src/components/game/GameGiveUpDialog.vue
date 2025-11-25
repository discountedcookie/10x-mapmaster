<script setup lang="ts">
import { ref } from 'vue'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { SearchX } from 'lucide-vue-next'
import type { PlaceWithScore } from '@/stores/game'

interface Props {
  open: boolean
  confidence: number
  threshold: number
  questionCount: number
  topCandidates: PlaceWithScore[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  'submit-place': [placeName: string]
  'play-again': []
}>()

const userAnswer = ref('')

const handleSubmitPlace = () => {
  if (userAnswer.value.trim()) {
    emit('submit-place', userAnswer.value.trim())
    userAnswer.value = ''
  }
}

const handlePlayAgain = () => {
  emit('play-again')
  userAnswer.value = ''
}

const confidencePercent = Math.round(props.confidence * 100)
const thresholdPercent = Math.round(props.threshold * 100)
</script>

<template>
  <Dialog :open="open" @update:open="(val) => emit('update:open', val)">
    <DialogContent class="max-w-2xl">
      <DialogHeader>
        <DialogTitle class="flex items-center gap-2 text-xl">
          <SearchX class="w-6 h-6 text-destructive" />
          I couldn't find it...
        </DialogTitle>
        <DialogDescription>
          After {{ questionCount }} questions, I'm only {{ confidencePercent }}% confident (needed
          {{ thresholdPercent }}%).
        </DialogDescription>
      </DialogHeader>

      <div class="space-y-4">
        <p class="text-sm text-muted-foreground">My best guesses were:</p>

        <div class="space-y-2 max-h-64 overflow-y-auto">
          <Card
            v-for="(candidate, idx) in topCandidates.slice(0, 3)"
            :key="candidate.id"
            class="hover:bg-muted/50 transition-colors"
          >
            <CardContent class="p-4 flex items-center justify-between">
              <div class="flex items-center gap-3">
                <span class="text-2xl">
                  {{ idx === 0 ? '🥇' : idx === 1 ? '🥈' : '🥉' }}
                </span>
                <div>
                  <p class="font-medium">{{ candidate.name }}</p>
                  <p class="text-sm text-muted-foreground">
                    {{ candidate.lat?.toFixed(4) ?? 'N/A' }}°,
                    {{ candidate.lng?.toFixed(4) ?? 'N/A' }}°
                  </p>
                </div>
              </div>
              <Badge variant="outline" class="font-mono">
                {{ Math.round(candidate.confidence * 100) }}%
              </Badge>
            </CardContent>
          </Card>
        </div>

        <Separator />

        <div class="space-y-3">
          <Label for="user-answer" class="text-base"> What place were you thinking of? </Label>
          <Input
            id="user-answer"
            v-model="userAnswer"
            placeholder="Enter place name..."
            class="text-lg"
            @keyup.enter="handleSubmitPlace"
          />
          <p class="text-xs text-muted-foreground">
            💡 Your answer will help improve the game for future players!
          </p>
        </div>
      </div>

      <DialogFooter class="gap-2">
        <Button variant="outline" @click="handlePlayAgain"> Start Over </Button>
        <Button :disabled="!userAnswer.trim()" @click="handleSubmitPlace"> Submit Place </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
