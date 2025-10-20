<script setup lang="ts">
import { computed } from 'vue'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import type { Tables } from '@/types/database'
import { LOW_CONFIDENCE_MIN, LOW_CONFIDENCE_MAX } from '@/stores/game'

interface PlaceWithScore extends Tables<'places'> {
  semantic_similarity: number
  spatial_confidence: number
  composite_confidence: number
}

interface Props {
  guess: PlaceWithScore | null
  disabled?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  correct: []
  incorrect: []
  playAgain: []
}>()

const confidencePercent = computed(() => {
  if (!props.guess?.composite_confidence) return
  return Math.round(props.guess.composite_confidence * 100)
})

const isLowConfidence = computed(() => {
  if (!props.guess) return false
  return props.guess.composite_confidence >= LOW_CONFIDENCE_MIN && props.guess.composite_confidence < LOW_CONFIDENCE_MAX
})

const semanticPercent = computed(() => {
  if (!props.guess?.semantic_similarity) return 0
  return Math.round(props.guess.semantic_similarity * 100)
})

const spatialPercent = computed(() => {
  if (!props.guess?.spatial_confidence) return 0
  return Math.round(props.guess.spatial_confidence * 100)
})
</script>

<template>
  <Card class="w-full max-w-2xl">
    <CardHeader>
      <CardTitle class="text-2xl">
        {{ guess && !isLowConfidence ? 'Is this your place?' : guess && isLowConfidence ? 'I\'m narrowing it down...' : 'No matches found' }}
      </CardTitle>
      <CardDescription v-if="!guess">
        We couldn't find a matching place. Please tell us what you were thinking of.
      </CardDescription>
      <CardDescription v-else-if="isLowConfidence">
        The description matches multiple places. Answer more questions to narrow down the results.
      </CardDescription>
    </CardHeader>
    <CardContent v-if="guess">
      <div class="space-y-3">
        <div>
          <h3 class="text-xl font-semibold">
            {{ guess.name }}
          </h3>
          <p class="text-sm text-muted-foreground">
            {{ guess.lat.toFixed(4) }}°, {{ guess.lng.toFixed(4) }}°
          </p>
        </div>

        <!-- Low confidence: show detailed breakdown -->
        <div
          v-if="isLowConfidence"
          class="space-y-2 p-3 bg-muted rounded-md"
        >
          <div class="text-sm font-medium">
            Match Analysis
          </div>
          <div class="space-y-1">
            <div class="flex justify-between text-sm">
              <span class="text-muted-foreground">Description match:</span>
              <span class="font-medium">{{ semanticPercent }}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-muted-foreground">Location clustering:</span>
              <span class="font-medium">{{ spatialPercent }}%</span>
            </div>
            <div class="flex justify-between text-sm border-t pt-1 mt-1">
              <span class="text-muted-foreground">Overall confidence:</span>
              <span class="font-semibold">{{ confidencePercent }}%</span>
            </div>
          </div>
        </div>

        <!-- High confidence: simple display -->
        <p
          v-else-if="confidencePercent !== undefined"
          class="text-sm text-muted-foreground"
        >
          Match confidence: {{ confidencePercent }}%
        </p>
      </div>
    </CardContent>
    <CardFooter class="flex gap-4">
      <template v-if="guess && !isLowConfidence">
        <Button
          class="flex-1"
          size="lg"
          :disabled="disabled"
          @click="emit('correct')"
        >
          Yes, that's it!
        </Button>
        <Button
          class="flex-1"
          size="lg"
          variant="outline"
          :disabled="disabled"
          @click="emit('incorrect')"
        >
          No, that's not it
        </Button>
      </template>
      <template v-else-if="guess && isLowConfidence">
        <Button
          class="flex-1"
          size="lg"
          :disabled="disabled"
          @click="emit('correct')"
        >
          Yes, it's this one
        </Button>
        <Button
          class="flex-1"
          size="lg"
          variant="outline"
          :disabled="disabled"
          @click="emit('incorrect')"
        >
          No, keep asking questions
        </Button>
      </template>
      <template v-else>
        <Button
          class="flex-1"
          size="lg"
          :disabled="disabled"
          @click="emit('incorrect')"
        >
          Tell us the place
        </Button>
        <Button
          class="flex-1"
          size="lg"
          variant="outline"
          :disabled="disabled"
          @click="emit('playAgain')"
        >
          Play Again
        </Button>
      </template>
    </CardFooter>
  </Card>
</template>
