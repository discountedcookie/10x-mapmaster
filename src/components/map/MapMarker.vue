<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { MglMarker, MglPopup } from '@indoorequal/vue-maplibre-gl'

interface Properties {
  coordinates: [number, number]
  name: string
  backgroundColor?: string
  opacity?: number
  similarity?: number
  gameCount?: number
  index?: number
  rank?: number // 1-based rank (1 = top candidate)
  threshold?: number // Winning threshold (default 0.85)
}

const properties = withDefaults(defineProps<Properties>(), {
  backgroundColor: '#3b82f6',
  opacity: 1,
  index: 0,
  rank: 999,
  threshold: 0.85,
})

const { t } = useI18n()

// Helper function to calculate marker color based on confidence
const getMarkerColor = (confidence: number): string => {
  // HSL color: 0=red (0%), 60=yellow (50%), 120=green (100%)
  const hue = confidence * 120
  return `hsl(${hue}, 70%, 50%)`
}

// Helper function to calculate marker size based on confidence and rank
const getMarkerSize = (confidence: number, rank: number): number => {
  if (rank === 1 && confidence > properties.threshold) {
    return 48 // Extra large for winning candidate
  } else if (rank <= 3) {
    // Top 3: size grows with confidence (20px to 40px)
    return 20 + confidence * 20
  } else {
    return 16 // Small for others
  }
}

// Computed marker styles
const markerStyle = computed(() => {
  const confidence = properties.similarity ?? 0
  const rank = properties.rank
  const isGameMarker = properties.similarity !== undefined

  if (!isGameMarker) {
    return {
      backgroundColor: properties.backgroundColor,
      opacity: properties.opacity,
      width: '28px',
      height: '28px',
      borderWidth: '2px',
    }
  }

  const size = getMarkerSize(confidence, rank)
  const color = getMarkerColor(confidence)
  const opacity = rank <= 3 ? 0.3 + confidence * 0.7 : 0.3

  return {
    backgroundColor: color,
    opacity,
    width: `${size}px`,
    height: `${size}px`,
    borderWidth: rank === 1 ? '4px' : '3px',
  }
})

// Computed classes for animations
const markerClasses = computed(() => {
  const confidence = properties.similarity ?? 0
  const rank = properties.rank
  const isWinner = rank === 1 && confidence > properties.threshold
  const isTopCandidate = rank === 1
  const isCloseToWin = rank === 1 && confidence > 0.75

  return {
    'animate-marker-pulse-glow': isTopCandidate && !isWinner,
    'animate-pulse': isTopCandidate,
    'radar-rings': isCloseToWin || isWinner,
    'animate-bounce-in': isWinner,
  }
})

// Determine if this is a game marker (has similarity score)
const isGameMarker = properties.similarity !== undefined
</script>

<template>
  <MglMarker :coordinates="coordinates">
    <template #marker>
      <div class="relative">
        <!-- Marker pin -->
        <div
          class="rounded-full border-white shadow-xl cursor-pointer hover:scale-110 transition-all duration-300"
          :class="markerClasses"
          :style="markerStyle"
          :aria-label="
            t('map.marker_aria_label', {
              name,
              percent: isGameMarker ? Math.round(similarity! * 100) : '',
            })
          "
        />

        <!-- Popper tooltip removed for cleaner map during active games -->
      </div>
    </template>

    <!-- Popup for non-game markers (fallback) -->
    <MglPopup v-if="!isGameMarker" :close-button="false">
      <div class="rounded-lg shadow-lg p-3 border bg-card text-card-foreground">
        <strong>{{ name }}</strong>
        <div v-if="gameCount && gameCount > 0" class="text-xs mt-1">
          {{ t('map.played', { count: gameCount }) }}
        </div>
      </div>
    </MglPopup>
  </MglMarker>
</template>
