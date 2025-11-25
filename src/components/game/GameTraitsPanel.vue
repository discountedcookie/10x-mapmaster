<script setup lang="ts">
import { useSemanticTraits } from '@/composables/game/useSemanticTraits'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'

interface Properties {
  gameState: import('@/stores/game').GameState
}

const properties = defineProps<Properties>()

const { affirmed, denied } = useSemanticTraits(properties.gameState.semanticConstraint)
</script>

<template>
  <Card class="p-4">
    <div class="space-y-3">
      <div>
        <h4 class="text-sm font-medium mb-2">Affirmed Traits</h4>
        <div class="flex flex-wrap gap-1">
          <Badge
            v-for="trait in affirmed"
            :key="trait"
            variant="default"
            class="bg-success text-success-foreground"
          >
            {{ trait }}
          </Badge>
          <span v-if="affirmed.length === 0" class="text-xs text-muted-foreground">None</span>
        </div>
      </div>

      <div>
        <h4 class="text-sm font-medium mb-2">Denied Traits</h4>
        <div class="flex flex-wrap gap-1">
          <Badge v-for="trait in denied" :key="trait" variant="outline">
            {{ trait }}
          </Badge>
          <span v-if="denied.length === 0" class="text-xs text-muted-foreground">None</span>
        </div>
      </div>
    </div>
  </Card>
</template>
