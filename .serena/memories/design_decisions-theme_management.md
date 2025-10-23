## Theme Management - Proper Persistence (October 21, 2025)

**Problem**: Theme preference wasn't persisting to localStorage, and map styles weren't switching when theme changed.

**Root Causes**:
1. `useColorMode` returns resolved theme (light/dark), not user preference (light/dark/auto)
2. MapLibre component doesn't react to `:map-style` prop changes
3. No separation between user preference and resolved theme

**Solution**: Custom theme composable with dual state management

**Implementation** (`src/composables/useTheme.ts`):
```typescript
export function useTheme() {
  // Store user preference separately (light/dark/auto)
  const preference = useStorage<'light' | 'dark' | 'auto'>('theme-preference', 'auto')

  // Get the actual resolved color mode (light/dark only)
  const colorMode = useColorMode({
    disableTransition: false,
    modes: {
      light: 'light',
      dark: 'dark',
    },
  })

  // Computed to get the resolved theme (what should actually be applied)
  const resolvedTheme = computed(() => {
    if (preference.value === 'auto') {
      return isSystemDark.value ? 'dark' : 'light'
    }
    return preference.value
  })

  const setTheme = (value: 'light' | 'dark' | 'auto') => {
    preference.value = value  // Persisted to localStorage
    if (value === 'auto') {
      colorMode.value = isSystemDark.value ? 'dark' : 'light'
    } else {
      colorMode.value = value
    }
  }

  return {
    preference,      // User's choice (light/dark/auto)
    resolvedTheme,   // What's actually applied (light/dark)
    setLight, setDark, setAuto
  }
}
```

**Map Style Switching**:
Used Vue's `key` attribute to force map recreation when theme changes:
```vue
<MglMap
  :key="mapStyle"
  :map-style="mapStyle"
  ...
/>
```

**Why `key` works**:
- Vue destroys and recreates component when `key` changes
- `mapStyle` computed returns different URL for each theme
- Simpler than manually calling MapLibre's `setStyle()` method
- No need to track map instance or watch for changes

**Benefits**:
- ✅ Theme preference persists across page reloads
- ✅ System theme (auto) works correctly
- ✅ Map recreates with correct Alidade style (Smooth / Smooth Dark)
- ✅ Clean separation of concerns (preference vs. resolved state)
- ✅ localStorage integration via `useStorage`
