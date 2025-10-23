<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
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

const { t } = useI18n()

/** Confidence level classification */
const level = computed(() => {
  if (props.confidence >= 0.8) return 'high'
  if (props.confidence >= 0.5) return 'medium'
  return 'low'
})

/** Badge label */
const label = computed(() => {
  const percent = Math.round(props.confidence * 100)
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
