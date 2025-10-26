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

// Map configuration - theme-aware styles using free OSM tiles
const mapStyle = computed(() => {
  const isDark = resolvedTheme.value === 'dark'
  return isDark
    ? 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json'
    : 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json'
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
