<script setup lang="ts">
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import BaseMap from '@/components/map/BaseMap.vue'

interface Props {
  bounds?: [[number, number], [number, number]]
}

const props = defineProps<Props>()
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <FloatingNavbar />

    <BaseMap :bounds="bounds">
      <slot name="markers" />
    </BaseMap>

    <slot name="overlay" />
  </div>
</template>
