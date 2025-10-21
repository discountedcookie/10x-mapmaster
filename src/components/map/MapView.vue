<script setup lang="ts">
import { computed } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { MglMap, MglMarker, MglPopup } from '@indoorequal/vue-maplibre-gl'

interface Candidate {
  lat: number
  lng: number
  name: string
  similarity?: number
  game_count?: number
}

interface Props {
  candidates?: Candidate[]
}

const props = withDefaults(defineProps<Props>(), {
  candidates: () => [],
})

const { resolvedTheme } = useTheme()

// Map configuration - theme-aware styles
const mapStyle = computed(() => {
  const isDark = resolvedTheme.value === 'dark'

  return isDark
    ? 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json'
    : 'https://tiles.stadiamaps.com/styles/alidade_smooth.json'
})

const mapCenter = [0, 20] as [number, number]
const mapZoom = 3

// Computed properties for markers
const markers = computed(() => {
  return props.candidates.map((candidate, index) => {
    const isGameContext = candidate.similarity !== undefined
    const backgroundColor = isGameContext ? '#ef4444' : '#3b82f6' // red-500 : blue-500
    const opacity = isGameContext ? 0.4 + (candidate.similarity! * 0.6) : 1

    let popupContent = `<strong>${candidate.name}</strong>`
    if (isGameContext) {
      popupContent += `<br><span style="font-size: 0.8em;">Match: ${Math.round(candidate.similarity! * 100)}%</span>`
    }
    else if (candidate.game_count && candidate.game_count > 0) {
      popupContent += `<br><span style="font-size: 0.8em;">Played ${candidate.game_count} time${candidate.game_count === 1 ? '' : 's'}</span>`
    }

    return {
      id: `marker-${index}`,
      coordinates: [candidate.lng, candidate.lat] as [number, number],
      backgroundColor,
      opacity,
      popupContent,
      name: candidate.name,
      similarity: candidate.similarity,
      game_count: candidate.game_count,
    }
  })
})

// Calculate bounds for all markers with padding
const bounds = computed(() => {
  if (props.candidates.length === 0) return

  const lngs = props.candidates.map(c => c.lng)
  const lats = props.candidates.map(c => c.lat)

  const minLng = Math.min(...lngs)
  const maxLng = Math.max(...lngs)
  const minLat = Math.min(...lats)
  const maxLat = Math.max(...lats)

  // Add 15% padding to bounds to avoid markers on the edge
  const lngPadding = (maxLng - minLng) * 0.15
  const latPadding = (maxLat - minLat) * 0.15

  // Return bounds in the format expected by MapLibre GL JS [[lng, lat], [lng, lat]]
  return [
    [minLng - lngPadding, minLat - latPadding],
    [maxLng + lngPadding, maxLat + latPadding],
  ] as [[number, number], [number, number]]
})

</script>

<template>
  <MglMap
    :map-style="mapStyle"
    :center="mapCenter"
    :zoom="mapZoom"
    :bounds="bounds"
    class="!absolute inset-0"
  >
    <MglMarker
      v-for="marker in markers"
      :key="marker.id"
      :coordinates="marker.coordinates"
    >
      <template #marker>
        <div
          class="w-6 h-6 rounded-full border-2 border-white shadow-lg cursor-pointer hover:scale-110 transition-transform"
          :style="{ backgroundColor: marker.backgroundColor, opacity: marker.opacity }"
          role="button"
          :aria-label="`View ${marker.name}${marker.similarity ? ` - ${Math.round(marker.similarity * 100)}% match` : ''}`"
        />
      </template>

      <MglPopup :close-button="false">
        <div
          class="rounded-lg shadow-lg p-3 border bg-card text-card-foreground"
        >
          <strong>{{ marker.name }}</strong>
          <div
            v-if="marker.similarity !== undefined"
            class="text-xs mt-1"
          >
            Match: {{ Math.round(marker.similarity * 100) }}%
          </div>
          <div
            v-else-if="marker.game_count && marker.game_count > 0"
            class="text-xs mt-1"
          >
            Played {{ marker.game_count }} time{{ marker.game_count === 1 ? '' : 's' }}
          </div>
        </div>
      </MglPopup>
    </MglMarker>
  </MglMap>
</template>
