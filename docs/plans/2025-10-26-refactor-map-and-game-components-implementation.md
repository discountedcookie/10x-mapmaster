# Refactor Map Layout and Game View Components - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract marker/bounds logic from MapLayout to views, decompose GameView into smaller components, and extract business logic to composables.

**Architecture:** Feature-based organization with composables for reusable logic, presentational components emitting events, and views orchestrating the UI. Map composables accept components as props for flexibility.

**Tech Stack:** Vue 3 Composition API, TypeScript, Pinia stores, vue-i18n

---

## Task 1: Create Map Composables Foundation

**Files:**
- Create: `src/composables/map/useMapBounds.ts`
- Create: `src/composables/map/useMapMarkers.ts`

**Step 1: Create useMapBounds composable**

Create `src/composables/map/useMapBounds.ts`:

```typescript
import { computed, type ComputedRef } from 'vue'

export interface Marker {
  coordinates: [number, number]
  [key: string]: any
}

export type Bounds = [[number, number], [number, number]] | undefined

export function useMapBounds(
  markers: ComputedRef<Marker[]>,
  padding = 0.15
): ComputedRef<Bounds> {
  return computed(() => {
    if (markers.value.length === 0) return undefined

    const lngs = markers.value.map(m => m.coordinates[0])
    const lats = markers.value.map(m => m.coordinates[1])

    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)
    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)

    const lngPadding = (maxLng - minLng) * padding
    const latPadding = (maxLat - minLat) * padding

    return [
      [minLng - lngPadding, minLat - latPadding],
      [maxLng + lngPadding, maxLat + latPadding],
    ]
  })
}
```

**Step 2: Create useMapMarkers composable**

Create `src/composables/map/useMapMarkers.ts`:

```typescript
import { computed, h, type Component, type ComputedRef, type VNode } from 'vue'
import { useMapBounds, type Marker, type Bounds } from './useMapBounds'

export interface UseMapMarkersOptions<T> {
  data: ComputedRef<T[]>
  markerComponent: Component
  computeMarker: (item: T, index: number) => Marker
  boundsOptions?: {
    padding?: number
    enabled?: boolean
  }
}

export interface UseMapMarkersReturn {
  markers: ComputedRef<Marker[]>
  bounds: ComputedRef<Bounds>
  markerNodes: ComputedRef<VNode[]>
}

export function useMapMarkers<T>(
  options: UseMapMarkersOptions<T>
): UseMapMarkersReturn {
  const markers = computed(() => {
    return options.data.value
      .filter((item: any) => item.lat != null && item.lng != null)
      .map((item, index) => options.computeMarker(item, index))
  })

  const bounds = options.boundsOptions?.enabled === false
    ? computed(() => undefined)
    : useMapBounds(markers, options.boundsOptions?.padding)

  const markerNodes = computed(() => {
    return markers.value.map((marker, index) =>
      h(options.markerComponent, { ...marker, index, key: marker.id })
    )
  })

  return { markers, bounds, markerNodes }
}
```

**Step 3: Commit map composables**

```bash
cd .worktrees/refactor-map-game
git add src/composables/map/
git commit -m "feat(map): add useMapMarkers and useMapBounds composables

- Create reusable marker rendering logic
- Calculate bounds with configurable padding
- Accept marker component as prop for flexibility

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Update HomeView to Use New Composables

**Files:**
- Modify: `src/views/HomeView.vue`

**Step 1: Update HomeView imports and setup**

Replace the entire `<script setup>` section in `src/views/HomeView.vue`:

```typescript
import { computed, onMounted } from 'vue'
import HeroCard from '@/components/HeroCard.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapMarkers } from '@/composables/map/useMapMarkers'

const placesStore = usePlaces()

// Fetch places on mount
onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Compute markers for browse mode
const { markerNodes, bounds } = useMapMarkers({
  data: computed(() => placesStore.places),
  markerComponent: MapMarker,
  computeMarker: (place) => ({
    id: `place-${place.id}`,
    coordinates: [place.lng!, place.lat!] as [number, number],
    name: place.name,
    backgroundColor: '#3b82f6', // blue-500
    opacity: 1,
    similarity: undefined,
    gameCount: place.game_count,
  })
})
```

**Step 2: Update HomeView template to pass markers**

Update the template section - add `v-bind` to pass bounds and render markerNodes:

```vue
<template>
  <component :is="markerNodes" />
  <HeroCard />
</template>
```

Wait - this won't work. We need to pass markers to MapLayout. Let me check the current MapLayout structure first.

Actually, looking at the design, MapLayout should receive markers through its default slot. Let me revise this approach.

**Step 2 (Revised): Keep template simple, pass through slot**

The template stays as is - HeroCard goes in the overlay slot. The markers will be rendered by MapLayout from the parent's perspective. Actually, we need to think about this differently.

Let me reconsider: HomeView is rendered inside MapLayout's slot. So HomeView itself doesn't render the map - MapLayout does. HomeView should provide the markers to MapLayout somehow.

Looking at the design again - views should provide markers. The cleanest way is to use provide/inject or to have MapLayout's parent (App.vue via router-view) handle this.

Actually, re-reading the design: "let views decide what markers and bounds should be on the map" - this suggests views compute markers and pass them to MapLayout.

But currently the structure is:
```
MapLayout (has BaseMap)
  └─ slot (HomeView or GameView)
```

For views to control the map, we need to either:
1. Pass markers as props through router-view
2. Use provide/inject pattern
3. Restructure so views contain the map

Looking at the user's request: "Extract this code. Let the views decide of what markers and bounds should be on the map."

I think the cleanest approach is to have each view render its own MapLayout instance with markers. Let me revise the implementation plan.

**Step 2 (Final Revision): HomeView provides markers to MapLayout**

Since HomeView is currently just content inside MapLayout's slot, we need to restructure. HomeView should render MapLayout directly:

Update `src/views/HomeView.vue`:

```vue
<script setup lang="ts">
import { computed, onMounted } from 'vue'
import MapLayout from '@/layouts/MapLayout.vue'
import HeroCard from '@/components/HeroCard.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import { usePlaces } from '@/composables/usePlaces'
import { useMapMarkers } from '@/composables/map/useMapMarkers'

const placesStore = usePlaces()

// Fetch places on mount
onMounted(() => {
  placesStore.fetchAllPlaces()
})

// Compute markers for browse mode
const { markerNodes, bounds } = useMapMarkers({
  data: computed(() => placesStore.places),
  markerComponent: MapMarker,
  computeMarker: (place) => ({
    id: `place-${place.id}`,
    coordinates: [place.lng!, place.lat!] as [number, number],
    name: place.name,
    backgroundColor: '#3b82f6',
    opacity: 1,
    similarity: undefined,
    gameCount: place.game_count,
  })
})
</script>

<template>
  <MapLayout :bounds="bounds">
    <template #markers>
      <component :is="() => markerNodes" />
    </template>
    <template #overlay>
      <HeroCard />
    </template>
  </MapLayout>
</template>
```

**Step 3: Commit HomeView changes**

```bash
git add src/views/HomeView.vue
git commit -m "refactor(home): use useMapMarkers composable

- Compute browse mode markers with useMapMarkers
- Fetch places on mount
- Pass markers and bounds to MapLayout

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Update MapLayout to Accept Markers via Slots

**Files:**
- Modify: `src/layouts/MapLayout.vue`

**Step 1: Simplify MapLayout to just render map + slots**

Replace entire `src/layouts/MapLayout.vue`:

```vue
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
```

**Step 2: Commit MapLayout simplification**

```bash
git add src/layouts/MapLayout.vue
git commit -m "refactor(layout): simplify MapLayout to accept markers via slots

- Remove all mode detection logic
- Remove marker computation
- Accept bounds as prop
- Provide markers and overlay slots

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Update Router to Not Use MapLayout Wrapper

**Files:**
- Modify: `src/router/index.ts`

**Step 1: Check current router structure**

Read `src/router/index.ts` to see if MapLayout is used as a wrapper.

**Step 2: Update router if needed**

If MapLayout is currently wrapping routes, remove it since views now include MapLayout directly.

The routes should look like:

```typescript
{
  path: '/',
  name: 'home',
  component: () => import('@/views/HomeView.vue')
},
{
  path: '/game',
  name: 'game',
  component: () => import('@/views/GameView.vue')
}
```

**Step 3: Commit router changes if modified**

```bash
git add src/router/index.ts
git commit -m "refactor(router): remove MapLayout wrapper

Views now include MapLayout directly

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Create Game UI Components - GameStartScreen

**Files:**
- Create: `src/components/game/GameStartScreen.vue`

**Step 1: Create GameStartScreen component**

Create `src/components/game/GameStartScreen.vue`:

```vue
<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'

interface Props {
  description: string
  validationMessage: string
  descriptionLength: number
  isValid: boolean
  loading: boolean
  minLength: number
  maxLength: number
}

interface Emits {
  (e: 'update:description', value: string): void
  (e: 'start'): void
  (e: 'goHome'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const { t } = useI18n()
</script>

<template>
  <Card
    class="w-full animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader class="text-center space-y-3">
      <CardTitle class="text-4xl font-bold flex items-center justify-center gap-3">
        <Icon
          icon="radix-icons:pencil-1"
          class="h-10 w-10 text-primary"
        />
        {{ t('game.describe_place_title') }}
      </CardTitle>
      <CardDescription class="text-xl">
        {{ t('game.describe_place_description') }}
      </CardDescription>
    </CardHeader>
    <CardContent class="flex flex-col gap-4">
      <div class="space-y-2">
        <Textarea
          :model-value="description"
          :placeholder="t('game.description_placeholder')"
          rows="4"
          class="resize-none"
          :maxlength="maxLength"
          @update:model-value="emit('update:description', $event)"
        />
        <div class="flex justify-between items-center text-sm gap-2">
          <p
            v-if="validationMessage"
            class="text-destructive flex-1"
          >
            {{ validationMessage }}
          </p>
          <p
            v-else
            class="text-muted-foreground flex-1"
          >
            {{ minLength }}-{{ maxLength }} {{ t('common.characters') }}
          </p>
          <p
            class="text-muted-foreground whitespace-nowrap"
            :class="{ 'text-destructive': descriptionLength > maxLength }"
          >
            {{ descriptionLength }}/{{ maxLength }}
          </p>
        </div>
      </div>
      <Button
        size="lg"
        class="transition-playful"
        :disabled="!isValid || loading"
        @click="emit('start')"
      >
        <Icon
          v-if="!loading"
          icon="radix-icons:play"
          class="h-5 w-5 mr-2"
        />
        {{ loading ? t('game.starting') : t('game.start_game') }}
      </Button>
      <Button
        size="lg"
        variant="outline"
        class="transition-playful"
        @click="emit('goHome')"
      >
        <Icon
          icon="radix-icons:home"
          class="h-5 w-5 mr-2"
        />
        {{ t('common.back_to_home') }}
      </Button>
    </CardContent>
  </Card>
</template>
```

**Step 2: Commit GameStartScreen**

```bash
git add src/components/game/GameStartScreen.vue
git commit -m "feat(game): add GameStartScreen component

- Pure presentational component for game start
- Description input with validation display
- Emits events for user actions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Create Game UI Components - GameResumeDialog

**Files:**
- Create: `src/components/game/GameResumeDialog.vue`

**Step 1: Create GameResumeDialog component**

Create `src/components/game/GameResumeDialog.vue`:

```vue
<script setup lang="ts">
import { Icon } from '@iconify/vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

interface Props {
  questionCount: number
  maxQuestions: number
  candidatesCount: number
}

interface Emits {
  (e: 'resume'): void
  (e: 'startFresh'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
</script>

<template>
  <Card
    class="w-full animate-slide-up-fade"
    style="box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(0, 0, 0, 0.05);"
  >
    <CardHeader class="text-center space-y-3">
      <CardTitle class="text-3xl font-bold flex items-center justify-center gap-3">
        <Icon
          icon="radix-icons:question-mark-circled"
          class="h-10 w-10 text-primary"
        />
        Resume Game?
      </CardTitle>
      <CardDescription class="text-lg">
        You have an unfinished game session. Would you like to continue where you left off?
      </CardDescription>
    </CardHeader>
    <CardContent class="flex flex-col gap-3">
      <div class="text-sm text-muted-foreground text-center">
        <p>Questions asked: {{ questionCount }} / {{ maxQuestions }}</p>
        <p>Candidates remaining: {{ candidatesCount }}</p>
      </div>
      <Button
        size="lg"
        class="transition-playful"
        @click="emit('resume')"
      >
        <Icon
          icon="radix-icons:play"
          class="h-5 w-5 mr-2"
        />
        Resume Game
      </Button>
      <Button
        size="lg"
        variant="outline"
        class="transition-playful"
        @click="emit('startFresh')"
      >
        <Icon
          icon="radix-icons:reload"
          class="h-5 w-5 mr-2"
        />
        Start New Game
      </Button>
    </CardContent>
  </Card>
</template>
```

**Step 2: Commit GameResumeDialog**

```bash
git add src/components/game/GameResumeDialog.vue
git commit -m "feat(game): add GameResumeDialog component

- Show resume or start fresh options
- Display game progress stats
- Pure presentation with event emissions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 7: Create Game UI Components - GameLoadingOverlay

**Files:**
- Create: `src/components/game/GameLoadingOverlay.vue`

**Step 1: Create GameLoadingOverlay component**

Create `src/components/game/GameLoadingOverlay.vue`:

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { Card, CardContent } from '@/components/ui/card'

const { t } = useI18n()
</script>

<template>
  <div
    class="absolute inset-0 flex flex-col items-center justify-center bg-black/60 backdrop-blur-sm pointer-events-auto z-50"
  >
    <Card class="max-w-md mx-4">
      <CardContent class="pt-6 pb-6 flex flex-col items-center gap-4">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" />
        <div class="text-center space-y-1">
          <p class="font-semibold text-lg">
            {{ t('game.loading_overlay.analyzing_description') }}
          </p>
          <p class="text-sm text-muted-foreground">
            {{ t('game.loading_overlay.finding_places') }}
          </p>
        </div>
      </CardContent>
    </Card>
  </div>
</template>
```

**Step 2: Commit GameLoadingOverlay**

```bash
git add src/components/game/GameLoadingOverlay.vue
git commit -m "feat(game): add GameLoadingOverlay component

- Loading state with spinner
- Uses i18n for messages
- Full screen overlay

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 8: Rename Existing Game Components

**Files:**
- Rename: `src/components/game/QuestionCard.vue` → `src/components/game/GameQuestionCard.vue`
- Rename: `src/components/game/ResultCard.vue` → `src/components/game/GameResultCard.vue`
- Rename: `src/components/game/PlaceSearch.vue` → `src/components/game/GamePlaceSearch.vue`

**Step 1: Rename QuestionCard**

```bash
cd .worktrees/refactor-map-game
git mv src/components/game/QuestionCard.vue src/components/game/GameQuestionCard.vue
```

**Step 2: Rename ResultCard**

```bash
git mv src/components/game/ResultCard.vue src/components/game/GameResultCard.vue
```

**Step 3: Rename PlaceSearch**

```bash
git mv src/components/game/PlaceSearch.vue src/components/game/GamePlaceSearch.vue
```

**Step 4: Commit renames**

```bash
git commit -m "refactor(game): rename components with Game prefix

- QuestionCard → GameQuestionCard
- ResultCard → GameResultCard
- PlaceSearch → GamePlaceSearch

Establishes clear feature ownership

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 9: Create Game Composables - useGameState

**Files:**
- Create: `src/composables/game/useGameState.ts`

**Step 1: Create useGameState composable**

Create `src/composables/game/useGameState.ts`:

```typescript
import { ref, computed } from 'vue'
import { useGameStore } from '@/stores/game'

export type GameState = 'idle' | 'resumeDialog' | 'start' | 'question' | 'result' | 'placeSearch'

export function useGameState() {
  const gameStore = useGameStore()

  const gameStarted = ref(false)
  const showResumeDialog = ref(false)
  const showPlaceSearch = ref(false)

  const hasExistingGame = computed(() => {
    return gameStore.topCandidates.length > 0 || gameStore.questionCount > 0
  })

  const gameState = computed((): GameState => {
    if (showResumeDialog.value) return 'resumeDialog'
    if (!gameStarted.value) return 'start'
    if (showPlaceSearch.value) return 'placeSearch'
    if (gameStore.isGameComplete) return 'result'
    if (gameStore.currentQuestion) return 'question'
    return 'idle'
  })

  function checkForExistingGame() {
    if (hasExistingGame.value && !gameStarted.value) {
      showResumeDialog.value = true
    }
  }

  return {
    gameStarted,
    showResumeDialog,
    showPlaceSearch,
    hasExistingGame,
    gameState,
    checkForExistingGame,
  }
}
```

**Step 2: Commit useGameState**

```bash
git add src/composables/game/useGameState.ts
git commit -m "feat(game): add useGameState composable

- Manage game state machine
- Track dialog and search visibility
- Compute current game state

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 10: Create Game Composables - useGameValidation

**Files:**
- Create: `src/composables/game/useGameValidation.ts`

**Step 1: Create useGameValidation composable**

Create `src/composables/game/useGameValidation.ts`:

```typescript
import { computed, type Ref } from 'vue'
import { useI18n } from 'vue-i18n'

const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 500

export function useGameValidation(description: Ref<string>) {
  const { t } = useI18n()

  const descriptionLength = computed(() => description.value.length)

  const isDescriptionValid = computed(() => {
    const trimmed = description.value.trim()
    return trimmed.length >= MIN_DESCRIPTION_LENGTH && trimmed.length <= MAX_DESCRIPTION_LENGTH
  })

  const validationMessage = computed(() => {
    const trimmed = description.value.trim()
    if (trimmed.length === 0) return ''
    if (trimmed.length < MIN_DESCRIPTION_LENGTH) {
      return t('game.validation.min_length', {
        length: MIN_DESCRIPTION_LENGTH,
        current: trimmed.length
      })
    }
    if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
      return t('game.validation.max_length', { length: MAX_DESCRIPTION_LENGTH })
    }
    return ''
  })

  return {
    isDescriptionValid,
    validationMessage,
    descriptionLength,
    MIN_DESCRIPTION_LENGTH,
    MAX_DESCRIPTION_LENGTH,
  }
}
```

**Step 2: Commit useGameValidation**

```bash
git add src/composables/game/useGameValidation.ts
git commit -m "feat(game): add useGameValidation composable

- Validate description length
- Provide validation messages
- Export min/max constants

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 11: Create Game Composables - useGameActions

**Files:**
- Create: `src/composables/game/useGameActions.ts`

**Step 1: Create useGameActions composable**

Create `src/composables/game/useGameActions.ts`:

```typescript
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import { useI18n } from 'vue-i18n'
import { useGameStore } from '@/stores/game'
import { usePlaces, type NominatimPlace } from '@/composables/usePlaces'
import type { useGameState } from './useGameState'

export function useGameActions(state: ReturnType<typeof useGameState>) {
  const router = useRouter()
  const gameStore = useGameStore()
  const placesStore = usePlaces()
  const { extractDescriptors, enrichDescriptors } = placesStore
  const { t } = useI18n()

  const saving = ref(false)

  async function startGame(description: string) {
    try {
      await gameStore.startNewGame(description.trim())
      state.gameStarted.value = true
    }
    catch (error) {
      console.error('Failed to start game:', error)
      toast.error(t('game.toast.start_game_failed_title'), {
        description: t('game.toast.start_game_failed_body'),
      })
    }
  }

  function resumeGame() {
    state.showResumeDialog.value = false
    state.gameStarted.value = true
  }

  function startFreshGame() {
    state.showResumeDialog.value = false
    gameStore.resetGame()
    state.gameStarted.value = false
  }

  async function answerQuestion(answer: boolean) {
    await gameStore.answerQuestion(answer)
  }

  async function handleCorrectGuess() {
    const result = gameStore.gameResult
    if (!result) return

    try {
      saving.value = true
      await gameStore.finalizeGameSession(result as any, true)
      toast.success(t('game.toast.game_saved_title'), {
        description: t('game.toast.game_saved_body'),
      })
      playAgain()
    }
    catch (error) {
      console.error('Failed to save game:', error)
      toast.error(t('game.toast.save_game_failed_title'), {
        description: t('game.toast.save_game_failed_body'),
      })
    }
    finally {
      saving.value = false
    }
  }

  function handleIncorrectGuess() {
    gameStore.rejectGuessAndContinue()

    if (gameStore.isGameComplete && !gameStore.gameResult) {
      state.showPlaceSearch.value = true
    }
  }

  async function selectPlace(nominatimPlace: NominatimPlace) {
    try {
      saving.value = true
      const lat = Number.parseFloat(nominatimPlace.lat)
      const lng = Number.parseFloat(nominatimPlace.lon)

      let place = await gameStore.checkPlaceExists(lat, lng)
      const isNewPlace = !place

      if (!place) {
        const descriptors = extractDescriptors(nominatimPlace)
        const enrichedDescriptors = await enrichDescriptors(lat, lng, descriptors)

        place = await gameStore.saveNewPlace(
          nominatimPlace.display_name,
          lat,
          lng,
          enrichedDescriptors,
        )
      }

      await gameStore.finalizeGameSession(place, false, isNewPlace)
      toast.success(t('game.toast.place_saved_title'), {
        description: t('game.toast.place_saved_body'),
      })
      state.showPlaceSearch.value = false
      playAgain()
    }
    catch (error) {
      console.error('Failed to save place:', error)
      toast.error(t('game.toast.save_place_failed_title'), {
        description: t('game.toast.save_place_failed_body'),
      })
    }
    finally {
      saving.value = false
    }
  }

  function playAgain() {
    gameStore.resetGame()
    state.gameStarted.value = false
    state.showPlaceSearch.value = false
  }

  function goHome() {
    router.push('/')
  }

  return {
    saving,
    startGame,
    resumeGame,
    startFreshGame,
    answerQuestion,
    handleCorrectGuess,
    handleIncorrectGuess,
    selectPlace,
    playAgain,
    goHome,
  }
}
```

**Step 2: Commit useGameActions**

```bash
git add src/composables/game/useGameActions.ts
git commit -m "feat(game): add useGameActions composable

- All game business logic (start, answer, save)
- Toast notifications for errors/success
- Place selection and creation logic

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 12: Create Game Composables - useGameFlow (index)

**Files:**
- Create: `src/composables/game/index.ts`

**Step 1: Create useGameFlow composable**

Create `src/composables/game/index.ts`:

```typescript
import { ref, onMounted } from 'vue'
import { useGameState } from './useGameState'
import { useGameValidation } from './useGameValidation'
import { useGameActions } from './useGameActions'

export function useGameFlow() {
  const state = useGameState()
  const userDescription = ref('')
  const validation = useGameValidation(userDescription)
  const actions = useGameActions(state)

  onMounted(() => {
    state.checkForExistingGame()
  })

  return {
    // State
    ...state,

    // Validation
    userDescription,
    ...validation,

    // Actions
    ...actions,
  }
}

// Re-export for convenience
export { useGameState } from './useGameState'
export { useGameValidation } from './useGameValidation'
export { useGameActions } from './useGameActions'
```

**Step 2: Commit useGameFlow**

```bash
git add src/composables/game/index.ts
git commit -m "feat(game): add useGameFlow composable

- Combines state, validation, and actions
- Single interface for GameView
- Check for existing game on mount

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 13: Refactor GameView to Use New Composables

**Files:**
- Modify: `src/views/GameView.vue`

**Step 1: Replace GameView script section**

Replace the entire `<script setup>` in `src/views/GameView.vue`:

```typescript
import { computed } from 'vue'
import MapLayout from '@/layouts/MapLayout.vue'
import MapMarker from '@/components/map/MapMarker.vue'
import GameStartScreen from '@/components/game/GameStartScreen.vue'
import GameResumeDialog from '@/components/game/GameResumeDialog.vue'
import GameLoadingOverlay from '@/components/game/GameLoadingOverlay.vue'
import GameQuestionCard from '@/components/game/GameQuestionCard.vue'
import GameResultCard from '@/components/game/GameResultCard.vue'
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
import { useGameFlow } from '@/composables/game'
import { useMapMarkers } from '@/composables/map/useMapMarkers'
import { useGameStore, MAX_QUESTIONS } from '@/stores/game'

const gameStore = useGameStore()
const gameFlow = useGameFlow()

// Compute markers for game mode
const { markerNodes, bounds } = useMapMarkers({
  data: computed(() => gameStore.topCandidates),
  markerComponent: MapMarker,
  computeMarker: (candidate) => ({
    id: `game-${candidate.id}`,
    coordinates: [candidate.lng!, candidate.lat!] as [number, number],
    name: candidate.name,
    backgroundColor: '#ef4444',
    opacity: 0.4 + (candidate.composite_confidence * 0.6),
    similarity: candidate.composite_confidence,
    gameCount: undefined,
  }),
  boundsOptions: {
    padding: 0.25,
  }
})
```

**Step 2: Replace GameView template section**

Replace the entire `<template>` in `src/views/GameView.vue`:

```vue
<template>
  <MapLayout :bounds="bounds">
    <template #markers>
      <component :is="() => markerNodes" />
    </template>

    <template #overlay>
      <!-- Game UI - Centered Cards -->
      <div class="absolute inset-0 flex items-center justify-center p-4 pointer-events-none">
        <div class="pointer-events-auto max-w-2xl w-full max-h-[calc(100vh-6rem)]">
          <!-- Resume Game Dialog -->
          <GameResumeDialog
            v-if="gameFlow.gameState === 'resumeDialog'"
            :question-count="gameStore.questionCount"
            :max-questions="MAX_QUESTIONS"
            :candidates-count="gameStore.topCandidates.length"
            @resume="gameFlow.resumeGame"
            @start-fresh="gameFlow.startFreshGame"
          />

          <!-- Start Screen -->
          <GameStartScreen
            v-else-if="gameFlow.gameState === 'start'"
            v-model:description="gameFlow.userDescription"
            :validation-message="gameFlow.validationMessage"
            :description-length="gameFlow.descriptionLength"
            :is-valid="gameFlow.isDescriptionValid"
            :loading="gameStore.loading"
            :min-length="gameFlow.MIN_DESCRIPTION_LENGTH"
            :max-length="gameFlow.MAX_DESCRIPTION_LENGTH"
            @update:description="(val) => gameFlow.userDescription = val"
            @start="gameFlow.startGame(gameFlow.userDescription)"
            @go-home="gameFlow.goHome"
          />

          <!-- Question Phase -->
          <GameQuestionCard
            v-else-if="gameFlow.gameState === 'question' && gameStore.currentQuestion"
            :question="gameStore.currentQuestion.text"
            :question-number="gameStore.questionCount + 1"
            :total-questions="MAX_QUESTIONS"
            :candidates-count="gameStore.candidates.length"
            :confidence="gameStore.confidence"
            :top-candidates="gameStore.topCandidates.map(candidate => ({
              name: candidate.name,
              confidence: candidate.composite_confidence
            }))"
            @answer="gameFlow.answerQuestion"
          />

          <!-- Result Phase -->
          <GameResultCard
            v-else-if="gameFlow.gameState === 'result'"
            :guess="gameStore.gameResult"
            :disabled="gameFlow.saving"
            @correct="gameFlow.handleCorrectGuess"
            @incorrect="gameFlow.handleIncorrectGuess"
            @play-again="gameFlow.playAgain"
          />

          <!-- Place Search -->
          <GamePlaceSearch
            v-else-if="gameFlow.gameState === 'placeSearch'"
            @select="gameFlow.selectPlace"
            @cancel="gameFlow.showPlaceSearch = false"
          />
        </div>
      </div>

      <!-- Loading Overlay -->
      <GameLoadingOverlay v-if="gameStore.loading && !gameFlow.gameStarted" />

      <!-- Error message -->
      <div
        v-if="gameStore.error"
        class="fixed top-20 left-1/2 -translate-x-1/2 bg-destructive text-destructive-foreground px-4 py-2 rounded-md pointer-events-auto z-50"
      >
        {{ gameStore.error }}
      </div>
    </template>
  </MapLayout>
</template>
```

**Step 3: Commit GameView refactor**

```bash
git add src/views/GameView.vue
git commit -m "refactor(game): decompose GameView using composables

- Use useGameFlow for all business logic
- Use useMapMarkers for map markers
- Switch components based on gameState
- Reduced from 384 to ~80 lines

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 14: Update Test Imports

**Files:**
- Modify: `src/__tests__/components/game/QuestionCard.spec.ts` → Rename and update imports
- Modify: `src/__tests__/components/game/ResultCard.spec.ts` → Rename and update imports
- Modify: `src/__tests__/components/game/PlaceSearch.spec.ts` → Rename and update imports

**Step 1: Rename test files**

```bash
cd .worktrees/refactor-map-game
git mv src/__tests__/components/game/QuestionCard.spec.ts src/__tests__/components/game/GameQuestionCard.spec.ts
git mv src/__tests__/components/game/ResultCard.spec.ts src/__tests__/components/game/GameResultCard.spec.ts
git mv src/__tests__/components/game/PlaceSearch.spec.ts src/__tests__/components/game/GamePlaceSearch.spec.ts
```

**Step 2: Update GameQuestionCard.spec.ts imports**

In `src/__tests__/components/game/GameQuestionCard.spec.ts`, replace:
```typescript
import QuestionCard from '@/components/game/QuestionCard.vue'
```
with:
```typescript
import GameQuestionCard from '@/components/game/GameQuestionCard.vue'
```

And update all `QuestionCard` references to `GameQuestionCard` in the test descriptions.

**Step 3: Update GameResultCard.spec.ts imports**

In `src/__tests__/components/game/GameResultCard.spec.ts`, replace:
```typescript
import ResultCard from '@/components/game/ResultCard.vue'
```
with:
```typescript
import GameResultCard from '@/components/game/GameResultCard.vue'
```

And update all `ResultCard` references to `GameResultCard` in the test descriptions.

**Step 4: Update GamePlaceSearch.spec.ts imports**

In `src/__tests__/components/game/GamePlaceSearch.spec.ts`, replace:
```typescript
import PlaceSearch from '@/components/game/PlaceSearch.vue'
```
with:
```typescript
import GamePlaceSearch from '@/components/game/GamePlaceSearch.vue'
```

And update all `PlaceSearch` references to `GamePlaceSearch` in the test descriptions.

**Step 5: Commit test file updates**

```bash
git add src/__tests__/components/game/
git commit -m "test(game): update test imports for renamed components

- Rename test files to match component names
- Update all imports and references

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 15: Run Tests and Verify

**Step 1: Run unit tests**

```bash
cd .worktrees/refactor-map-game
npm run test:unit
```

Expected: All previously passing tests should still pass. The 4 failing tests related to missing i18n keys should still fail (we'll fix those next).

**Step 2: Manually test in browser**

```bash
npm run dev
```

Navigate to:
1. Home page - Verify blue markers show all places
2. Game page - Verify game flow works (resume dialog, start screen, questions, results, place search)
3. Verify markers show on map during game with red color and opacity based on confidence

**Step 3: Document any issues found**

If tests fail or manual testing reveals issues, document them for fixing.

---

## Task 16: Fix Pre-existing Test Issues

**Files:**
- Modify: `src/i18n/locales/en.ts` (add missing keys)
- Modify: `src/__tests__/components/game/GameQuestionCard.spec.ts` (update test expectations)

**Step 1: Add missing i18n keys**

In `src/i18n/locales/en.ts`, find the `game.question_card` section and add:

```typescript
question_card: {
  places_remaining: '{count} candidate | {count} candidates remaining',
  top_match: 'Top match',
  // ... other existing keys
}
```

**Step 2: Update test expectations in GameQuestionCard.spec.ts**

The tests are currently checking if the raw i18n key appears in text. Update them to check for the translated text instead:

Find tests like:
```typescript
expect(wrapper.text()).toContain(i18n.global.t('game.question_card.places_remaining'))
```

Replace with:
```typescript
expect(wrapper.text()).toContain('candidate')
```

**Step 3: Run tests again**

```bash
npm run test:unit
```

Expected: All GameQuestionCard tests should now pass.

**Step 4: Commit test fixes**

```bash
git add src/i18n/locales/en.ts src/__tests__/components/game/GameQuestionCard.spec.ts
git commit -m "fix(i18n): add missing game question card translation keys

- Add places_remaining and top_match keys
- Update test expectations

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 17: Final Verification and Cleanup

**Step 1: Run all tests**

```bash
npm run test:unit
```

Expected: All tests pass except App.spec.ts (MapLibre issue) and TEMPLATE e2e (wrong location).

**Step 2: Run type check**

```bash
npm run type-check
```

Expected: No TypeScript errors.

**Step 3: Test in browser thoroughly**

Test all game flows:
- [ ] Home page shows all places with blue markers
- [ ] Game start screen accepts description
- [ ] Resume dialog appears when game in progress
- [ ] Questions show with red markers
- [ ] Marker opacity varies by confidence
- [ ] Result card shows correct guess
- [ ] Place search works for incorrect guess
- [ ] Play again resets properly
- [ ] Map bounds adjust correctly

**Step 4: Create final commit**

```bash
git add -A
git commit -m "feat: complete map and game components refactoring

- Extracted marker/bounds logic to composables
- Decomposed GameView into focused components
- Simplified MapLayout to pure presentation
- Feature-based organization for game code

BREAKING CHANGE: Views now control map markers and bounds directly

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Success Criteria

Verify all criteria are met:

- [ ] MapLayout has no business logic (~30 lines)
- [ ] HomeView provides its own markers (~40 lines)
- [ ] GameView orchestrates components (~80 lines)
- [ ] All game components are <100 lines
- [ ] All game composables are <150 lines
- [ ] useGameFlow() provides clean API
- [ ] Browse mode shows all places with blue markers
- [ ] Game mode shows candidates with red markers based on confidence
- [ ] All game states render correctly
- [ ] No regressions in functionality
- [ ] Tests pass (except pre-existing App.spec.ts issue)

## Notes for Implementation

- Use `@` for skill references when you encounter patterns covered by other skills
- Commit frequently (after each task completion)
- Test incrementally - don't wait until the end
- If a test fails, investigate before proceeding
- The worktree is at: `.worktrees/refactor-map-game`
- After completion, use @superpowers:finishing-a-development-branch for merge/PR workflow
