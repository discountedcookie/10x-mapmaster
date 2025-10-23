## Shared Map Layout (October 21, 2025)

**Problem**: Map was blinking/recreating when navigating between HomeView and GameView.

**Root Cause**: Each view had its own `<MapView>` component that was unmounted/mounted on route change.

**Solution**: Create shared `MapLayout.vue` that wraps both views with single persistent map instance.

**Implementation** (`src/layouts/MapLayout.vue`):
```vue
<script setup>
// Shared layout manages single map instance
const mapCandidates = computed(() => {
  // In game view, show game candidates when there are candidates
  if (route.name === 'game' && gameStore.topCandidates.length > 0) {
    return gameStore.topCandidates.map(place => ({...}))
  }
  // Otherwise show all places (home view or game not started)
  return allPlaces.value
})
</script>

<template>
  <SidebarProvider>
    <AppSidebar />
    <SidebarInset>
      <MapView :candidates="mapCandidates" />
      <slot /> <!-- View-specific content -->
    </SidebarInset>
  </SidebarProvider>
</template>
```

**Benefits**:
- ✅ Single map instance persists across routes (no blinking)
- ✅ Centralized sidebar + map structure
- ✅ Views focus only on overlay content
- ✅ Map candidates update reactively based on route and game state
- ✅ Better performance (no map re-initialization)
