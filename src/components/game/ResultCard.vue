<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { Icon } from '@iconify/vue'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible'
import ConfidenceBadge from '@/components/ConfidenceBadge.vue'
import type { Tables } from '@/types/database'
import { LOW_CONFIDENCE_MIN, LOW_CONFIDENCE_MAX } from '@/stores/game'

interface PlaceWithScore extends Tables<'places'> {
  semantic_similarity: number
  spatial_confidence: number
  composite_confidence: number
}

interface Props {
  guess: PlaceWithScore | null
  disabled?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  correct: []
  incorrect: []
  playAgain: []
}>()

const { t } = useI18n()

const showAnalysis = ref(false)

const confidencePercent = computed(() => {
  if (!props.guess?.composite_confidence) return
  return Math.round(props.guess.composite_confidence * 100)
})

const isLowConfidence = computed(() => {
  if (!props.guess) return false
  return props.guess.composite_confidence >= LOW_CONFIDENCE_MIN && props.guess.composite_confidence < LOW_CONFIDENCE_MAX
})

const semanticPercent = computed(() => {
  if (!props.guess?.semantic_similarity) return 0
  return Math.round(props.guess.semantic_similarity * 100)
})

const spatialPercent = computed(() => {
  if (!props.guess?.spatial_confidence) return 0
  return Math.round(props.guess.spatial_confidence * 100)
})
</script>

<template>
  <Card
    class="w-full max-w-2xl animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader>
      <CardTitle class="text-2xl flex items-center gap-2">
        {{ guess && !isLowConfidence ? t('game.result_card.is_this_your_place') : guess && isLowConfidence ? t('game.result_card.narrowing_down') : t('game.result_card.no_matches') }}
        <Icon
          v-if="guess && !isLowConfidence"
          icon="radix-icons:target"
          class="h-6 w-6 text-primary"
        />
      </CardTitle>
      <CardDescription v-if="!guess">
        {{ t('game.result_card.no_match_found_description') }}
      </CardDescription>
      <CardDescription v-else-if="isLowConfidence">
        {{ t('game.result_card.low_confidence_description') }}
      </CardDescription>
    </CardHeader>
    <CardContent v-if="guess">
      <div class="space-y-4">
        <div>
          <h3 class="text-xl font-semibold">
            {{ guess.name }}
          </h3>
          <p class="text-sm text-muted-foreground">
            {{ guess.lat?.toFixed(4) ?? 'N/A' }}°, {{ guess.lng?.toFixed(4) ?? 'N/A' }}°
          </p>
        </div>

        <!-- Confidence Badge -->
        <div class="flex items-center gap-2">
          <span class="text-sm text-muted-foreground">{{ t('game.result_card.overall_match') }}:</span>
          <ConfidenceBadge :confidence="guess.composite_confidence" />
        </div>

        <!-- Collapsible Match Analysis -->
        <Collapsible v-model:open="showAnalysis">
          <CollapsibleTrigger as-child>
            <Button
              variant="ghost"
              size="sm"
              class="w-full justify-between p-2"
            >
              <span class="text-sm font-medium">
                <Icon
                  icon="radix-icons:bar-chart"
                  class="inline h-4 w-4 mr-1"
                />
                {{ t('game.result_card.match_analysis') }}
              </span>
              <Icon
                :icon="showAnalysis ? 'radix-icons:chevron-up' : 'radix-icons:chevron-down'"
                class="h-4 w-4 transition-transform"
              />
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent class="space-y-3 pt-3">
            <div class="space-y-3">
              <!-- Description Match -->
              <div class="space-y-1">
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">{{ t('game.result_card.description_match') }}</span>
                  <span class="font-medium">{{ semanticPercent }}%</span>
                </div>
                <Progress
                  :model-value="semanticPercent"
                  class="h-2"
                />
              </div>

              <!-- Location Clustering -->
              <div class="space-y-1">
                <div class="flex justify-between text-sm">
                  <span class="text-muted-foreground">{{ t('game.result_card.location_clustering') }}</span>
                  <span class="font-medium">{{ spatialPercent }}%</span>
                </div>
                <Progress
                  :model-value="spatialPercent"
                  class="h-2"
                />
              </div>
            </div>
          </CollapsibleContent>
        </Collapsible>
      </div>
    </CardContent>
    <CardFooter class="flex gap-4">
      <template v-if="guess && !isLowConfidence">
        <Button
          class="flex-1 transition-playful"
          size="lg"
          :disabled="disabled"
          @click="emit('correct')"
        >
          <Icon
            icon="radix-icons:check"
            class="h-5 w-5 mr-2"
          />
          {{ t('game.result_card.yes_thats_it') }}
        </Button>
        <Button
          class="flex-1 transition-playful"
          size="lg"
          variant="outline"
          :disabled="disabled"
          @click="emit('incorrect')"
        >
          <Icon
            icon="radix-icons:cross-2"
            class="h-5 w-5 mr-2"
          />
          {{ t('game.result_card.no_thats_not_it') }}
        </Button>
      </template>
      <template v-else-if="guess && isLowConfidence">
        <Button
          class="flex-1 transition-playful"
          size="lg"
          :disabled="disabled"
          @click="emit('correct')"
        >
          <Icon
            icon="radix-icons:check"
            class="h-5 w-5 mr-2"
          />
          {{ t('game.result_card.yes_its_this_one') }}
        </Button>
        <Button
          class="flex-1 transition-playful"
          size="lg"
          variant="outline"
          :disabled="disabled"
          @click="emit('incorrect')"
        >
          <Icon
            icon="radix-icons:question-mark"
            class="h-5 w-5 mr-2"
          />
          {{ t('game.result_card.no_keep_asking') }}
        </Button>
      </template>
      <template v-else>
        <Button
          class="flex-1 transition-playful"
          size="lg"
          :disabled="disabled"
          @click="emit('incorrect')"
        >
          <Icon
            icon="radix-icons:pencil-1"
            class="h-5 w-5 mr-2"
          />
          {{ t('game.result_card.tell_us_the_place') }}
        </Button>
        <Button
          class="flex-1 transition-playful"
          size="lg"
          variant="outline"
          :disabled="disabled"
          @click="emit('playAgain')"
        >
          <Icon
            icon="radix-icons:reload"
            class="h-5 w-5 mr-2"
          />
          {{ t('game.play_again') }}
        </Button>
      </template>
    </CardFooter>
  </Card>
</template>
