<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useMapState } from '@/composables/map/useMapState'
import { useGameStore } from '@/stores/game'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const router = useRouter()
const { locale } = useI18n()

const { clearMapState } = useMapState()
const gameStore = useGameStore()

// Clear map state when HomeView mounts (show all places, no candidates)
onMounted(() => {
  clearMapState()
})

// Description input
const description = ref('')

// Handle start game
async function handleStartGame() {
  if (!description.value.trim()) return

  try {
    await gameStore.startNewGame(description.value, locale.value)

    // Redirect to game view with session ID
    if (gameStore.gameSessionId) {
      await router.push(`/game/${gameStore.gameSessionId}`)
    }
  } catch (error) {
    console.error('Failed to start game:', error)
  }
}
</script>

<template>
  <!-- Bottom-positioned Card Container -->
  <div class="relative flex justify-center items-end h-full pb-4 px-4 pointer-events-none">
    <Card class="w-full md:max-w-md pointer-events-auto">
      <CardHeader>
        <CardTitle class="text-center">Describe a place</CardTitle>
      </CardHeader>
      <CardContent class="space-y-4">
        <Input
          v-model="description"
          placeholder="e.g., A famous tower in Paris"
          @keyup.enter="handleStartGame"
        />
        <Button
          class="w-full"
          :disabled="!description.trim() || gameStore.loading"
          @click="handleStartGame"
        >
          {{ gameStore.loading ? 'Starting...' : 'Start Game' }}
        </Button>
      </CardContent>
    </Card>
  </div>
</template>
