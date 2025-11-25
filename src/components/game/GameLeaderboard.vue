<script setup lang="ts">
import { computed } from 'vue'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Trophy, TrendingUp, TrendingDown, Minus } from 'lucide-vue-next'
import type { PlaceWithScore } from '@/stores/game'

interface Props {
  candidates: PlaceWithScore[]
  previousScores?: Map<string, number> // Map of place ID to previous confidence
  maxCandidates?: number
}

const props = withDefaults(defineProps<Props>(), {
  maxCandidates: 3,
})

// Get top candidates
const topCandidates = computed(() => {
  return props.candidates.slice(0, props.maxCandidates)
})

// Helper function to calculate marker color based on confidence
const getMarkerColor = (confidence: number): string => {
  const hue = confidence * 120
  return `hsl(${hue}, 70%, 50%)`
}

// Calculate delta (change in confidence)
const getDelta = (placeId: string, currentConfidence: number): number | null => {
  if (!props.previousScores) return null
  const previousConfidence = props.previousScores.get(placeId)
  if (previousConfidence === undefined) return null
  return currentConfidence - previousConfidence
}

// Get emoji for rank
const getRankEmoji = (rank: number): string => {
  const emojis = ['🥇', '🥈', '🥉']
  return emojis[rank - 1] || `#${rank}`
}
</script>

<template>
  <Card
    class="fixed top-20 right-4 w-80 bg-background/90 backdrop-blur-md shadow-2xl border-2 z-40 hidden md:block"
  >
    <CardHeader class="pb-3">
      <CardTitle class="text-lg flex items-center gap-2">
        <Trophy class="w-5 h-5 text-yellow-500" />
        Top Matches
      </CardTitle>
    </CardHeader>
    <CardContent class="space-y-2">
      <div
        v-for="(candidate, i) in topCandidates"
        :key="candidate.id"
        class="flex items-center gap-3 p-3 rounded-lg transition-all duration-300"
        :class="i === 0 ? 'bg-primary/10 border-2 border-primary' : 'bg-muted/50'"
      >
        <!-- Rank -->
        <span class="text-2xl min-w-[2rem] text-center">
          {{ getRankEmoji(i + 1) }}
        </span>

        <!-- Marker Preview -->
        <div
          class="min-w-[12px] w-3 h-3 rounded-full shadow-lg transition-all duration-300"
          :class="{ 'animate-pulse': i === 0 }"
          :style="{
            background: getMarkerColor(candidate.confidence),
            boxShadow: i === 0 ? `0 0 10px ${getMarkerColor(candidate.confidence)}` : 'none',
          }"
        />

        <!-- Info -->
        <div class="flex-1 min-w-0">
          <p class="font-medium truncate text-sm">{{ candidate.name }}</p>
          <p class="text-xs text-muted-foreground truncate">
            {{ candidate.lat?.toFixed(4) ?? 'N/A' }}°, {{ candidate.lng?.toFixed(4) ?? 'N/A' }}°
          </p>
        </div>

        <!-- Score with Delta -->
        <div class="text-right">
          <p class="font-mono font-bold text-sm">{{ Math.round(candidate.confidence * 100) }}%</p>
          <p
            v-if="getDelta(candidate.id, candidate.confidence) !== null"
            class="text-xs flex items-center gap-0.5 justify-end"
            :class="{
              'text-green-500': getDelta(candidate.id, candidate.confidence)! > 0,
              'text-red-500': getDelta(candidate.id, candidate.confidence)! < 0,
              'text-muted-foreground': getDelta(candidate.id, candidate.confidence) === 0,
            }"
          >
            <component
              :is="
                getDelta(candidate.id, candidate.confidence)! > 0
                  ? TrendingUp
                  : getDelta(candidate.id, candidate.confidence)! < 0
                    ? TrendingDown
                    : Minus
              "
              class="w-3 h-3"
            />
            {{ Math.abs(Math.round(getDelta(candidate.id, candidate.confidence)! * 100)) }}
          </p>
        </div>
      </div>

      <!-- Empty state -->
      <div v-if="topCandidates.length === 0" class="text-center py-8 text-muted-foreground text-sm">
        No candidates yet
      </div>
    </CardContent>
  </Card>
</template>
