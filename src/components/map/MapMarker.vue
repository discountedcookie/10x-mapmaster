<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { createPopper } from '@popperjs/core'
import type { Instance as PopperInstance, Placement } from '@popperjs/core'
import { useI18n } from 'vue-i18n'
import { MglMarker, MglPopup } from '@indoorequal/vue-maplibre-gl'

interface Props {
  coordinates: [number, number]
  name: string
  backgroundColor?: string
  opacity?: number
  similarity?: number
  gameCount?: number
  index?: number
}

const props = withDefaults(defineProps<Props>(), {
  backgroundColor: '#3b82f6',
  opacity: 1,
  index: 0,
})

const { t } = useI18n()

// Refs for Popper
const markerRef = ref<HTMLElement>()
const tooltipRef = ref<HTMLElement>()
let popperInstance: PopperInstance | undefined

// Determine if this is a game marker (has similarity score)
const isGameMarker = props.similarity !== undefined

// Calculate placement based on index to avoid overlap
const getPlacement = (index: number): Placement => {
  const placements: Placement[] = ['top', 'top-start', 'top-end', 'bottom', 'bottom-start', 'bottom-end', 'left', 'right']
  return placements[index % placements.length] || 'top'
}

onMounted(async () => {
  await nextTick()

  // Only create Popper for game markers (with similarity scores)
  if (isGameMarker && markerRef.value && tooltipRef.value) {
    popperInstance = createPopper(markerRef.value, tooltipRef.value, {
      placement: getPlacement(props.index),
      strategy: 'fixed',
      modifiers: [
        {
          name: 'offset',
          options: {
            offset: [0, 12],
          },
        },
        {
          name: 'preventOverflow',
          options: {
            padding: 16,
            boundary: 'viewport',
          },
        },
        {
          name: 'flip',
          options: {
            fallbackPlacements: ['top', 'bottom', 'left', 'right', 'top-start', 'top-end', 'bottom-start', 'bottom-end'],
          },
        },
        {
          name: 'shift',
          options: {
            padding: 8,
          },
        },
        {
          name: 'hide',
        },
      ],
    })

    // Force update after a short delay to ensure proper positioning
    setTimeout(() => {
      if (popperInstance) {
        popperInstance.update()
      }
    }, 100)
  }
})

// Watch for changes and update Popper
watch([markerRef, tooltipRef], () => {
  if (popperInstance) {
    popperInstance.update()
  }
})

onUnmounted(() => {
  if (popperInstance) {
    popperInstance.destroy()
  }
})
</script>

<template>
  <MglMarker :coordinates="coordinates">
    <template #marker>
      <div class="relative">
        <!-- Marker pin -->
        <div
          ref="markerRef"
          class="w-7 h-7 rounded-full border-2 border-white shadow-xl cursor-pointer hover:scale-110 transition-transform"
          :class="{ 'animate-pulse': isGameMarker }"
          :style="{
            backgroundColor,
            opacity,
            borderWidth: isGameMarker ? '3px' : '2px'
          }"
          :aria-label="t('map.marker_aria_label', {
            name,
            percent: isGameMarker ? Math.round(similarity! * 100) : ''
          })"
        />

        <!-- Popper tooltip only for game markers -->
        <div
          v-if="isGameMarker"
          ref="tooltipRef"
          class="popper-tooltip px-3 py-2 rounded-lg shadow-xl border-2 bg-card/98 text-card-foreground backdrop-blur-md whitespace-nowrap max-w-xs z-50"
          data-popper-arrow
        >
          <div class="text-sm font-semibold truncate">
            {{ name }}
          </div>
          <div class="text-xs text-muted-foreground">
            {{ t('map.match') }}: {{ Math.round(similarity! * 100) }}%
          </div>
        </div>
      </div>
    </template>

    <!-- Popup for non-game markers (fallback) -->
    <MglPopup
      v-if="!isGameMarker"
      :close-button="false"
    >
      <div class="rounded-lg shadow-lg p-3 border bg-card text-card-foreground">
        <strong>{{ name }}</strong>
        <div
          v-if="gameCount && gameCount > 0"
          class="text-xs mt-1"
        >
          {{ t('map.played', { count: gameCount }) }}
        </div>
      </div>
    </MglPopup>
  </MglMarker>
</template>
