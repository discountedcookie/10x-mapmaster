<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Toaster } from '@/components/ui/sonner'
import MapLayout from '@/layouts/MapLayout.vue'

const authStore = useAuthStore()

onMounted(() => {
  authStore.initialize()
})
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
