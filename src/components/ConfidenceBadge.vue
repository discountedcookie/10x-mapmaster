<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Badge } from '@/components/ui/badge'
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip'

interface Properties {
  /** Confidence score (0-1) */
  confidence: number
  /** Show tooltip with explanation */
  showTooltip?: boolean
}

const properties = withDefaults(defineProps<Properties>(), {
  showTooltip: true,
})

const { t } = useI18n()

/** Confidence level classification
 * Note: Receives normalized confidence (15-95% range)
 * Thresholds adjusted for percentile-normalized scores
 */
const level = computed(() => {
  // High: 75%+ of normalized range (0.75 normalized = ~75% raw score)
  if (properties.confidence >= 0.75) return 'high'
  // Medium: 45-75% of normalized range
  if (properties.confidence >= 0.45) return 'medium'
  // Low: below 45%
  return 'low'
})

/** Badge label */
const label = computed(() => {
  const percent = Math.round(properties.confidence * 100)
  if (level.value === 'high') return t('confidence.high', { percent })
  if (level.value === 'medium') return t('confidence.medium', { percent })
  return t('confidence.low', { percent })
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
    return t('confidence.tooltip.high')
  }
  if (level.value === 'medium') {
    return t('confidence.tooltip.medium')
  }
  return t('confidence.tooltip.low')
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
        <Badge :variant="variant" :class="badgeClasses">
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
  <Badge v-else :variant="variant" :class="badgeClasses">
    {{ label }}
  </Badge>
</template>
