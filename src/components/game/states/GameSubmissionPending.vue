<script setup lang="ts">
import { watch, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useGameSearchStore } from '@/stores/gameSearch'
import { useGameMap } from '@/composables/game/useGameMap'
import { usePlacePresentation } from '@/composables/map/usePlacePresentation'

const { t } = useI18n({ useScope: 'global' })

interface Properties {
  title?: string
}

defineProps<Properties>()

const router = useRouter()
const searchStore = useGameSearchStore()
const { camera } = useGameMap()

// Presentation mode for submission pending state with orbital rotation
const presentation = usePlacePresentation({
  getPlace: () => {
    if (searchStore.submittedPlace) {
      return { lng: searchStore.submittedPlace.lng, lat: searchStore.submittedPlace.lat }
    }
    return null
  },
  interactionMode: 'zoom-only',
})

// When place is submitted (pending review), zoom to it with 3D pitch and start rotation
watch(
  () => searchStore.isSubmissionPending,
  async (isPending) => {
    if (isPending && searchStore.submittedPlace && camera.isLoaded.value) {
      await camera.flyTo({
        center: [searchStore.submittedPlace.lng, searchStore.submittedPlace.lat],
        zoom: 14,
        pitch: 55,
        bearing: 0,
        duration: 1500,
      })
      // Start orbital rotation after fly completes
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
         <p class="text-2xl">{{ t('game.thank_you') }}</p>
         <p class="text-muted-foreground">
           {{ t('game.submission_pending') }}
         </p>
         <Button class="w-full" @click="router.push('/')">{{ t('game.new_game') }}</Button>
       </div>
     </CardContent>
  </div>
</template>
