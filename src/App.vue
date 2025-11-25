<script setup lang="ts">
import { RouterView } from 'vue-router'
import { Toaster } from '@/components/ui/sonner'
import MapLayout from '@/layouts/MapLayout.vue'
</script>

<template>
  <div>
    <!-- Map layout for all views -->
    <MapLayout>
      <RouterView />
    </MapLayout>

    <Toaster />
  </div>
</template>
