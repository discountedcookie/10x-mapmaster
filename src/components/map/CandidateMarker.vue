<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'

interface Props {
  name: string
  confidence: number // 0-1
  zoom: number
  highlighted?: boolean // True when hovering in the search panel
}

const props = defineProps<Props>()

// Fade in/out labels based on zoom level
const opacity = computed(() => {
  if (props.zoom < 3) return 0
  if (props.zoom < 4) return props.zoom - 3 // Fade in: 0 to 1 between zoom 3-4
  if (props.zoom > 11) return Math.max(0, 12 - props.zoom) // Fade out: 1 to 0 between zoom 11-12
  return 1
})

// Confidence percentage
const confidencePercent = computed(() => Math.round(props.confidence * 100))

// Border color based on confidence (grey → primary blue)
const normalizedConfidence = computed(() => Math.max(0, (props.confidence - 0.5) * 2))
const borderColor = computed(() => {
  if (props.highlighted) {
    return 'hsl(220, 90%, 50%)' // Bright blue when highlighted
  }
  const saturation = normalizedConfidence.value * 80
  return `hsl(220, ${saturation}%, 55%)`
})

// Scale up when highlighted
const transform = computed(() => (props.highlighted ? 'scale(1.15)' : 'scale(1)'))
</script>

<template>
  <Badge
    variant="outline"
    class="whitespace-nowrap shadow-md transition-all duration-200 backdrop-blur-sm bg-background/50 border-2 px-2 py-1 rounded-sm"
    :class="{ 'ring-2 ring-primary/50 ring-offset-1': highlighted }"
    :style="{ opacity, borderColor, transform }"
  >
    {{ name }}
    <span class="ml-1 text-muted-foreground text-[10px]">{{ confidencePercent }}%</span>
  </Badge>
</template>
