<script setup lang="ts">
import HeroCard from '@/components/HeroCard.vue'
import MapView from '@/components/map/MapView.vue'
</script>

<template>
  <div class="relative h-screen w-screen">
    <MapView />
    <div class="pointer-events-none absolute inset-0 z-10 flex items-center justify-center">
      <div class="pointer-events-auto">
        <HeroCard />
      </div>
    </div>
  </div>
</template>
