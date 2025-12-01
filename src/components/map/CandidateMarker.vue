<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'

interface Properties {
  name: string
  confidence: number // 0-1
  zoom: number
  highlighted?: boolean // True when hovering in the search panel
}

const properties = defineProps<Properties>()

// Fade in/out labels based on zoom level
const opacity = computed(() => {
  if (properties.zoom < 3) return 0
  if (properties.zoom < 4) return properties.zoom - 3 // Fade in: 0 to 1 between zoom 3-4
  if (properties.zoom > 11) return Math.max(0, 12 - properties.zoom) // Fade out: 1 to 0 between zoom 11-12
  return 1
})

// Confidence percentage
const confidencePercent = computed(() => Math.round(properties.confidence * 100))

// Border color based on confidence (grey → primary blue)
const normalizedConfidence = computed(() => Math.max(0, (properties.confidence - 0.5) * 2))
const borderColor = computed(() => {
  if (properties.highlighted) {
    return 'hsl(220, 90%, 50%)' // Bright blue when highlighted
  }
  const saturation = normalizedConfidence.value * 80
  return `hsl(220, ${saturation}%, 55%)`
})

// Scale up when highlighted
const transform = computed(() => (properties.highlighted ? 'scale(1.15)' : 'scale(1)'))
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
