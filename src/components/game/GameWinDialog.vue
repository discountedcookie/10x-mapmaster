<script setup lang="ts">
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { Trophy, Target, MessageSquare, Sparkles } from 'lucide-vue-next'
import type { PlaceWithScore } from '@/stores/game'

interface Props {
  open: boolean
  place: PlaceWithScore
  questionCount: number
  confidence: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  'play-again': []
}>()

const confidencePercent = Math.round(props.confidence * 100)

// Get congratulations message based on question count
const getCongratulationsMessage = (count: number): string => {
  if (count <= 2) return "Incredible! You're a true geography master!"
  if (count <= 3) return 'Amazing! You gave great clues!'
  if (count <= 4) return 'Well done! Great description!'
  return 'Success! The place has been found!'
}
</script>

<template>
  <Dialog :open="open" @update:open="(val) => emit('update:open', val)">
    <DialogContent class="max-w-xl">
      <DialogHeader>
        <DialogTitle class="flex items-center justify-center gap-2 text-2xl">
          <Trophy class="w-8 h-8 text-yellow-500 animate-bounce" />
          <span class="animate-celebrate">Found It!</span>
          <Trophy class="w-8 h-8 text-yellow-500 animate-bounce" />
        </DialogTitle>
        <DialogDescription class="text-center text-base">
          {{ getCongratulationsMessage(questionCount) }}
        </DialogDescription>
      </DialogHeader>

      <div class="space-y-4 py-4">
        <!-- Winner Card -->
        <Card class="border-2 border-primary bg-gradient-to-br from-primary/10 to-primary/5">
          <CardContent class="p-6 text-center space-y-3">
            <div class="text-4xl mb-2">🎯</div>
            <h3 class="text-2xl font-bold">{{ place.name }}</h3>
            <p class="text-muted-foreground">
              {{ place.lat?.toFixed(4) ?? 'N/A' }}°, {{ place.lng?.toFixed(4) ?? 'N/A' }}°
            </p>

            <div class="flex items-center justify-center gap-2 pt-2">
              <Sparkles class="w-5 h-5 text-yellow-500" />
              <Badge variant="default" class="text-lg px-4 py-1 font-mono">
                {{ confidencePercent }}% Match
              </Badge>
              <Sparkles class="w-5 h-5 text-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <!-- Stats -->
        <div class="grid grid-cols-2 gap-4">
          <Card>
            <CardContent class="p-4 text-center">
              <div class="flex items-center justify-center gap-2 mb-1">
                <MessageSquare class="w-4 h-4 text-muted-foreground" />
                <p class="text-sm text-muted-foreground">Questions</p>
              </div>
              <p class="text-3xl font-bold">{{ questionCount }}</p>
            </CardContent>
          </Card>

          <Card>
            <CardContent class="p-4 text-center">
              <div class="flex items-center justify-center gap-2 mb-1">
                <Target class="w-4 h-4 text-muted-foreground" />
                <p class="text-sm text-muted-foreground">Confidence</p>
              </div>
              <p class="text-3xl font-bold">{{ confidencePercent }}%</p>
            </CardContent>
          </Card>
        </div>
      </div>

      <DialogFooter>
        <Button class="w-full" size="lg" @click="emit('play-again')">
          <Trophy class="w-4 h-4 mr-2" />
          Play Again
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
