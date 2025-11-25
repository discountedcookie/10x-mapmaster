<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'

interface Properties {
  gameState: import('@/stores/game').GameState
}

const properties = defineProps<Properties>()

const topCandidates = computed(() => properties.gameState.candidates.slice(0, 5))
</script>

<template>
  <Card class="p-4">
    <h4 class="text-sm font-medium mb-3">Top Candidates</h4>

    <div class="max-h-64 overflow-auto">
      <div class="space-y-2">
        <div
          v-for="(candidate, index) in topCandidates"
          :key="candidate.id"
          :class="[
            'p-3 rounded-lg border',
            index === 0 ? 'border-primary bg-primary/5' : 'border-border',
          ]"
        >
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <div class="font-medium">
                {{ candidate.name }}
              </div>
              <div class="text-xs text-muted-foreground">
                {{ candidate.lat }}, {{ candidate.lng }}
              </div>
            </div>
            <Badge variant="secondary"> {{ Math.round(candidate.confidence * 100) }}% </Badge>
          </div>
        </div>

        <div
          v-if="topCandidates.length === 0"
          class="text-xs text-muted-foreground text-center py-4"
        >
          No candidates yet
        </div>
      </div>
    </div>
  </Card>
</template>
