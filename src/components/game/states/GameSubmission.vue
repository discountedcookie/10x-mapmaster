<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { CardContent } from '@/components/ui/card'
import { logger } from '@/lib/logger'
import { useGameSessionStore } from '@/stores/gameSession'
import { useGameSearchStore } from '@/stores/gameSearch'
import { useGameMap } from '@/composables/game/useGameMap'
import { calculateBounds } from '@/lib/map-utils'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import type { NominatimPlace } from '@/composables/usePlaces'

const { t } = useI18n({ useScope: 'global' })

const router = useRouter()
const gameSessionStore = useGameSessionStore()
const gameSearchStore = useGameSearchStore()
const { camera } = useGameMap()

async function handlePlaceSubmit(place: NominatimPlace) {
  try {
    const osmId = `${place.osm_type}/${place.osm_id}`

    gameSearchStore.setSubmittedPlace({
      name: place.display_name,
      lat: Number.parseFloat(place.lat),
      lng: Number.parseFloat(place.lon),
    })

    await gameSessionStore.submitPlace(osmId)
  } catch (error) {
    logger.error('Failed to submit place:', error)
    gameSearchStore.clearSubmittedPlace()
  }
}

function handleSearchResults(places: NominatimPlace[]) {
  gameSearchStore.setSearchResultPlaces(places)

  if (places.length > 0 && camera?.isLoaded.value) {
    const searchCoords = places.map((p) => ({
      lng: Number.parseFloat(p.lon),
      lat: Number.parseFloat(p.lat),
    }))
    const bounds = calculateBounds(searchCoords)
    camera.fitBounds(bounds, { padding: 100, duration: 1000, maxZoom: 10 })
  }
}

function handleSearchCancel() {
  gameSearchStore.clearSearchResultPlaces()
  router.push('/')
}

function handlePlaceHover(place: NominatimPlace | undefined) {
  if (place) {
    // Use nominatim-{place_id} to match the ID format in searchResultPlaces
  }
}
</script>

<template>
   <CardContent class="space-y-4 pt-6">
     <div class="text-center space-y-2">
       <p class="text-xl font-semibold">{{ t('game.i_give_up') }}</p>
       <p class="text-muted-foreground">{{ t('game.help_me_learn') }}</p>
     </div>

    <GamePlaceSearch
      @select="handlePlaceSubmit"
      @cancel="handleSearchCancel"
      @search-results="handleSearchResults"
      @hover="handlePlaceHover"
    />
  </CardContent>
</template>
