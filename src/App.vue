<script setup lang="ts">
import { RouterView } from 'vue-router'
import { Toaster } from '@/components/ui/sonner'
import FloatingNavbar from '@/components/FloatingNavbar.vue'
import BaseMap from '@/components/map/BaseMap.vue'
</script>

<template>
  <div class="relative w-full h-screen overflow-hidden">
    <FloatingNavbar />

    <BaseMap class="absolute inset-0" />

    <!-- Current route view (handles its own teleport for layers) -->
    <RouterView class="absolute inset-0 pointer-events-none" />

    <Toaster />
  </div>
</template>
