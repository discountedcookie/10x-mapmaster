<script setup lang="ts">
import { computed, watch, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useGameSessionStore } from '@/stores/gameSession'
import { useGameMap } from '@/composables/game/useGameMap'
import { usePlacePresentation } from '@/composables/map/usePlacePresentation'

const { t } = useI18n({ useScope: 'global' })

interface Properties {
  title?: string
}

interface PlaceJson {
  id: string
  name: string
  lat: number | null
  lng: number | null
}

defineProps<Properties>()

const router = useRouter()
const gameStore = useGameSessionStore()
const { camera } = useGameMap()

// Narrow session JSON payload to shallow win-state shape
const session = computed(
  () =>
    gameStore.session as {
      place: PlaceJson | null
      question_count: number | null
    } | null
)

const place = computed<PlaceJson | null>(() => {
  return session.value?.place ?? null
})

const questionCount = computed(() => session.value?.question_count ?? 1)

// Presentation mode for win state with orbital rotation
const presentation = usePlacePresentation({
  getPlace: () => {
    const value = place.value
    if (!value || value.lat == null || value.lng == null) return null
    return { lng: value.lng, lat: value.lat }
  },
  interactionMode: 'zoom-only',
})

// When game is won, zoom to place and start rotation
watch(
  () => gameStore.isWon,
  async (isWon) => {
    const value = place.value
    if (isWon && value && value.lat != null && value.lng != null && camera?.isLoaded.value) {
      await camera.flyTo({
        center: [value.lng, value.lat],
        zoom: 14,
        pitch: 55,
        bearing: 0,
        duration: 1500,
      })
      presentation.startRotation()
    }
  },
  { immediate: true }
)

// Cleanup on unmount
onUnmounted(() => {
  presentation.stop()
})
</script>

<template>
  <div>
    <CardHeader v-if="title">
      <CardTitle class="text-center">
        {{ title }}
      </CardTitle>
    </CardHeader>
     <CardContent class="space-y-4">
       <div class="text-center space-y-4">
         <p class="text-2xl">{{ t('game.too_easy') }}</p>
         <p class="text-muted-foreground">
           {{ t('game.guessed_in', { count: questionCount }) }}
         </p>
         <Button class="w-full" @click="router.push('/')">{{ t('game.new_game') }}</Button>
       </div>
     </CardContent>
  </div>
</template>
