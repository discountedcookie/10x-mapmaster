<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { usePlaces, type NominatimPlace } from '@/composables/usePlaces'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Search, MapPin, Loader2, X } from 'lucide-vue-next'

const emit = defineEmits<{
  select: [place: NominatimPlace]
  cancel: []
  searchResults: [places: NominatimPlace[]]
  hover: [place: NominatimPlace | undefined]
}>()

const placesStore = usePlaces()
const { t } = useI18n()

const query = ref('')
const results = ref<NominatimPlace[]>([])
const selectedIndex = ref<number | undefined>()
const debounceTimeout = ref<ReturnType<typeof setTimeout> | undefined>()

watch(query, (newQuery) => {
  if (debounceTimeout.value) {
    clearTimeout(debounceTimeout.value)
  }

  if (!newQuery.trim()) {
    results.value = []
    emit('searchResults', [])
    return
  }

  debounceTimeout.value = setTimeout(async () => {
    try {
      results.value = await placesStore.searchPlaces(newQuery)
      emit('searchResults', results.value)
    } catch {
      // Error is already handled in store
      emit('searchResults', [])
    }
  }, 800) // Debounce for 800ms to respect Nominatim rate limit
})

function selectPlace(place: NominatimPlace, index: number) {
  selectedIndex.value = index
  emit('select', place)
}

function handleHover(place: NominatimPlace | undefined) {
  emit('hover', place)
}

function clearSearch() {
  query.value = ''
  results.value = []
  selectedIndex.value = undefined
  emit('searchResults', [])
  emit('hover', undefined)
}

// Parse display_name to extract primary name and location details
function parseDisplayName(displayName: string): { name: string; details: string } {
  const parts = displayName.split(', ')
  if (parts.length <= 1) {
    return { name: displayName, details: '' }
  }
  return {
    name: parts[0] ?? displayName,
    details: parts.slice(1, 4).join(', '), // Show next 3 parts
  }
}

// Get OSM type badge variant
function getOsmTypeBadge(osmType: string): string {
   switch (osmType) {
     case 'way': {
       return t('game.place_search.osm_type_building')
     }
     case 'relation': {
       return t('game.place_search.osm_type_area')
     }
     case 'node': {
       return t('game.place_search.osm_type_point')
     }
     default: {
       return osmType
     }
   }
 }
</script>

<template>
  <div class="space-y-4">
    <!-- Search input -->
    <div class="relative">
      <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
      <Input
        v-model="query"
        type="text"
        :placeholder="t('game.place_search.placeholder')"
        class="pl-10 pr-10 h-12 text-base"
      />
      <button
        v-if="query"
        class="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
        @click="clearSearch"
      >
        <X class="h-4 w-4" />
      </button>
    </div>

    <!-- Loading state -->
    <div
      v-if="placesStore.searchLoading"
      class="flex items-center justify-center py-8 text-muted-foreground"
    >
      <Loader2 class="h-5 w-5 animate-spin mr-2" />
      <span>{{ t('game.place_search.searching') }}</span>
    </div>

    <!-- Error state -->
    <div v-else-if="placesStore.searchError" class="text-center py-4">
      <p class="text-sm text-destructive">{{ placesStore.searchError }}</p>
    </div>

     <!-- Results -->
     <div v-else-if="results.length > 0" class="space-y-2">
       <p class="text-xs text-muted-foreground uppercase tracking-wide font-medium px-1">
         {{ t('game.place_search.results_found', { count: results.length }) }}
       </p>

      <div class="space-y-2 max-h-72 overflow-y-auto pr-1">
        <button
          v-for="(result, index) in results"
          :key="result.place_id"
          :class="[
            'w-full p-4 text-left rounded-lg border transition-all duration-200',
            'hover:border-primary hover:bg-primary/5 hover:shadow-md',
            'focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2',
            selectedIndex === index
              ? 'border-primary bg-primary/10 shadow-md'
              : 'border-border bg-card',
          ]"
          @click="selectPlace(result, index)"
          @mouseenter="handleHover(result)"
          @mouseleave="handleHover(undefined)"
        >
          <div class="flex items-start gap-3">
            <!-- Map pin icon -->
            <div class="flex-shrink-0 mt-0.5">
              <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                <MapPin class="h-4 w-4 text-primary" />
              </div>
            </div>

            <!-- Place info -->
            <div class="flex-1 min-w-0">
              <div class="flex items-start justify-between gap-2">
                <p class="font-medium text-foreground truncate">
                  {{ parseDisplayName(result.display_name).name }}
                </p>
                <Badge variant="secondary" class="flex-shrink-0 text-xs">
                  {{ getOsmTypeBadge(result.osm_type) }}
                </Badge>
              </div>

              <p class="text-sm text-muted-foreground mt-0.5 line-clamp-2">
                {{ parseDisplayName(result.display_name).details }}
              </p>

              <div class="flex items-center gap-2 mt-2">
                <Badge variant="outline" class="text-xs font-mono">
                  {{ parseFloat(result.lat).toFixed(4) }}°
                </Badge>
                <Badge variant="outline" class="text-xs font-mono">
                  {{ parseFloat(result.lon).toFixed(4) }}°
                </Badge>
              </div>
            </div>
          </div>
        </button>
      </div>
    </div>

     <!-- Empty state -->
     <div v-else-if="query && !placesStore.searchLoading" class="text-center py-8">
       <MapPin class="h-8 w-8 mx-auto text-muted-foreground/50 mb-2" />
       <p class="text-sm text-muted-foreground">{{ t('game.place_search.no_results') }}</p>
     </div>

     <!-- Initial state -->
     <div v-else class="text-center py-8">
       <Search class="h-8 w-8 mx-auto text-muted-foreground/50 mb-2" />
       <p class="text-sm text-muted-foreground">{{ t('game.place_search.search_placeholder') }}</p>
     </div>

    <Separator />

    <!-- Cancel button -->
    <Button variant="outline" class="w-full" @click="emit('cancel')">
      {{ t('common.cancel') }}
    </Button>
  </div>
</template>
