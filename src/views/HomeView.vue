<script setup lang="ts">
import HeroCard from '@/components/HeroCard.vue'
</script>

<template>
  <!-- Hero Card centered -->
  <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
    <div class="pointer-events-auto">
      <HeroCard />
    </div>
  </div>
</template>
