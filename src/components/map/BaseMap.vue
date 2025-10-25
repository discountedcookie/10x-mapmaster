<script setup lang="ts">
import { computed, ref } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { MglMap } from '@indoorequal/vue-maplibre-gl'

interface Props {
  bounds?: [[number, number], [number, number]]
  center?: [number, number]
  zoom?: number
}

const props = withDefaults(defineProps<Props>(), {
  center: () => [0, 20],
  zoom: 3,
})

const { resolvedTheme } = useTheme()
const mapRef = ref()

// Map configuration - theme-aware styles
const mapStyle = computed(() => {
  const isDark = resolvedTheme.value === 'dark'
  return isDark
    ? 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json'
    : 'https://tiles.stadiamaps.com/styles/alidade_smooth.json'
})
</script>

<template>
  <div class="absolute inset-0">
    <MglMap
      ref="mapRef"
      :map-style="mapStyle"
      :center="center"
      :zoom="zoom"
      :bounds="bounds"
    >
      <slot />
    </MglMap>
  </div>
</template>
