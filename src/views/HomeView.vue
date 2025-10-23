<script setup lang="ts">
import { onMounted } from 'vue'
import HeroCard from '@/components/HeroCard.vue'
import { usePlaces } from '@/composables/usePlaces'

const placesStore = usePlaces()

onMounted(() => {
  placesStore.fetchAllPlaces()
})
</script>

<template>
  <!-- Hero Card centered -->
  <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <HeroCard />
    </div>
  </div>
</template>
