<script setup lang="ts">
import { ref } from 'vue'
import { useGameStore } from '@/stores/game'
import { usePlaces, type NominatimPlace } from '@/composables/usePlaces'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import GamePlaceSearch from './GamePlaceSearch.vue'

interface Properties {
  open: boolean
}

interface Emits {
  close: []
}

const properties = defineProps<Properties>()
const emit = defineEmits<Emits>()

const gameStore = useGameStore()
const placesStore = usePlaces()

const selectedPlace = ref<NominatimPlace | null>(null)
const submitting = ref(false)

const handlePlaceSelect = (place: NominatimPlace) => {
  selectedPlace.value = place
}

const handleSubmit = async () => {
  if (!selectedPlace.value) return

  try {
    submitting.value = true
    // Format: "{osm_type}/{osm_id}" e.g. "way/5013364"
    const osmId = `${selectedPlace.value.osm_type}/${selectedPlace.value.osm_id}`
    await gameStore.submitActualPlace(
      selectedPlace.value.display_name,
      Number.parseFloat(selectedPlace.value.lat),
      Number.parseFloat(selectedPlace.value.lon),
      osmId
    )
    emit('close')
  } catch (error) {
    console.error('Failed to submit place:', error)
  } finally {
    submitting.value = false
  }
}

const handleCancel = () => {
  selectedPlace.value = null
  emit('close')
}
</script>

<template>
  <Dialog :open="open" @open-change="handleCancel">
    <DialogContent class="max-w-4xl max-h-[80vh] overflow-y-auto">
      <DialogHeader>
        <DialogTitle>Submit the Place You Were Thinking Of</DialogTitle>
        <DialogDescription>
          Since we couldn't guess your place, please help us learn by submitting it. Search for the
          place below and we'll add it to our database.
        </DialogDescription>
      </DialogHeader>

      <div class="py-4">
        <GamePlaceSearch @select="handlePlaceSelect" @cancel="handleCancel" />
      </div>

      <DialogFooter>
        <Button variant="outline" @click="handleCancel"> Cancel </Button>
        <Button :disabled="!selectedPlace || submitting" @click="handleSubmit">
          {{ submitting ? 'Submitting...' : 'Submit Place' }}
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
