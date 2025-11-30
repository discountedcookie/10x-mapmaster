<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'

interface Props {
  name: string
  zoom: number
}

const props = defineProps<Props>()

// Fade in/out labels based on zoom level
// Visible between zoom 4-12, hidden when zoomed out or zoomed in to 3D layer
const opacity = computed(() => {
  if (props.zoom < 4) return 0
  if (props.zoom < 5) return props.zoom - 4 // Fade in: 0 to 1 between zoom 4-5
  if (props.zoom > 11) return Math.max(0, 12 - props.zoom) // Fade out: 1 to 0 between zoom 11-12
  return 1
})

// Disable pointer events when invisible
const pointerEvents = computed(() => (props.zoom >= 4 && props.zoom <= 12 ? 'auto' : 'none'))
</script>

<template>
  <div
    class="cursor-pointer select-none transition-opacity duration-300"
    :style="{ opacity, pointerEvents }"
  >
    <Badge
      variant="secondary"
      class="whitespace-nowrap shadow-md backdrop-blur-sm bg-background/80 text-foreground border-border/50"
    >
      {{ name }}
    </Badge>
  </div>
</template>
