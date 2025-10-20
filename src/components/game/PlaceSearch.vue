<script setup lang="ts">
import { ref, watch } from 'vue'
import { useNominatim, type NominatimPlace } from '@/composables/useNominatim'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'

const emit = defineEmits<{
  select: [place: NominatimPlace]
  cancel: []
}>()

const { search, loading, error } = useNominatim()

const query = ref('')
const results = ref<NominatimPlace[]>([])
const debounceTimeout = ref<ReturnType<typeof setTimeout> | undefined>(undefined)

watch(query, (newQuery) => {
  if (debounceTimeout.value) {
    clearTimeout(debounceTimeout.value)
  }

  if (!newQuery.trim()) {
    results.value = []
    return
  }

  debounceTimeout.value = setTimeout(async () => {
    try {
      results.value = await search(newQuery)
    }
    catch {
      // Error is already handled in composable
    }
  }, 1000) // Debounce for 1 second to respect Nominatim rate limit
})

function selectPlace(place: NominatimPlace) {
  emit('select', place)
}
</script>

<template>
  <Card class="w-full max-w-2xl">
    <CardHeader>
      <CardTitle>What place were you thinking of?</CardTitle>
      <CardDescription>Search for the place you had in mind</CardDescription>
    </CardHeader>
    <CardContent class="space-y-4">
      <div class="space-y-2">
        <input
          v-model="query"
          type="text"
          placeholder="Search for a place..."
          class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
        >
        <p
          v-if="loading"
          class="text-sm text-muted-foreground"
        >
          Searching...
        </p>
        <p
          v-if="error"
          class="text-sm text-destructive"
        >
          {{ error }}
        </p>
      </div>

      <div
        v-if="results.length > 0"
        class="space-y-2 max-h-64 overflow-y-auto"
      >
        <button
          v-for="result in results"
          :key="result.place_id"
          class="w-full p-3 text-left rounded-md border border-input hover:bg-accent hover:text-accent-foreground transition-colors"
          @click="selectPlace(result)"
        >
          <p class="font-medium">
            {{ result.display_name }}
          </p>
          <p class="text-sm text-muted-foreground">
            {{ result.lat }}, {{ result.lon }}
          </p>
        </button>
      </div>
    </CardContent>
    <CardFooter>
      <Button
        variant="outline"
        class="w-full"
        @click="emit('cancel')"
      >
        Cancel
      </Button>
    </CardFooter>
  </Card>
</template>
