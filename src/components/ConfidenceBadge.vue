<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip'

interface Props {
  /** Confidence score (0-1) */
  confidence: number
  /** Show tooltip with explanation */
  showTooltip?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showTooltip: true,
})

/** Confidence level classification */
const level = computed(() => {
  if (props.confidence >= 0.8) return 'high'
  if (props.confidence >= 0.5) return 'medium'
  return 'low'
})

/** Badge label */
const label = computed(() => {
  const percent = Math.round(props.confidence * 100)
  if (level.value === 'high') return `High (${percent}%)`
  if (level.value === 'medium') return `Medium (${percent}%)`
  return `Low (${percent}%)`
})

/** Badge variant based on confidence level */
const variant = computed(() => {
  if (level.value === 'high') return 'default' // Uses primary color
  if (level.value === 'medium') return 'secondary'
  return 'outline'
})

/** Tooltip explanation */
const tooltipText = computed(() => {
  if (level.value === 'high') {
    return 'Strong match! The description closely matches this place.'
  }
  if (level.value === 'medium') {
    return 'Moderate match. May need a few more questions to be certain.'
  }
  return 'Weak match. This is one of several possibilities.'
})

/** Custom classes for badge color */
const badgeClasses = computed(() => {
  if (level.value === 'high') {
    return 'bg-[--success] text-[--success-foreground] hover:bg-[--success]/80'
  }
  if (level.value === 'medium') {
    return 'bg-[--warning] text-[--warning-foreground] hover:bg-[--warning]/80'
  }
  return ''
})
</script>

<template>
  <TooltipProvider v-if="showTooltip">
    <Tooltip>
      <TooltipTrigger as-child>
        <Badge
          :variant="variant"
          :class="badgeClasses"
        >
          {{ label }}
        </Badge>
      </TooltipTrigger>
      <TooltipContent>
        <p class="text-sm">
          {{ tooltipText }}
        </p>
      </TooltipContent>
    </Tooltip>
  </TooltipProvider>
  <Badge
    v-else
    :variant="variant"
    :class="badgeClasses"
  >
    {{ label }}
  </Badge>
</template>
