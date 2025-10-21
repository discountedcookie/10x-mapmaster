# Design Decisions Log

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

**User Experience**:
1. Default: "auto" (follows system preference)
2. User changes to "dark" → persisted to localStorage
3. Page reload → "dark" theme restored
4. Map always matches current theme

**Technical Details**:
- `preference` stored in localStorage as "theme-preference"
- `resolvedTheme` computed from preference + system setting
- `colorMode` applies CSS classes to document element
- Map recreation on theme change ensures correct style loads

---

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

**Architecture**:
- Layout component manages map and sidebar
- Views provide content via default slot
- Map candidates computed from current route + game state
- Shared places state prevents redundant fetches

**User Experience**:
- Seamless navigation between Home and Game
- Map stays rendered, only markers update
- No visual "jump" or loading states when switching views

---

## Shared Places State - Singleton Pattern (October 21, 2025)

**Problem**: Places were being fetched separately in HomeView and GameView, causing map to reload and jump when navigating between views.

**Solution**: Convert `usePlaces` composable to singleton pattern with shared state.

**Implementation**:
```typescript
// Shared state at module level (outside composable function)
const places = ref<Place[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
let fetchPromise: Promise<void> | null = null

export function usePlaces() {
  async function fetchAllPlaces() {
    // If already loaded, don't fetch again
    if (places.value.length > 0) {
      return
    }
    
    // If already fetching, return existing promise (prevents race conditions)
    if (fetchPromise) {
      return fetchPromise
    }
    
    // ... fetch logic
  }
}
```

**Benefits**:
- Places fetched only once per session
- No map jumping when switching views
- Shared reactive state across components
- Prevents race conditions (multiple simultaneous fetches)
- Better performance (one network request instead of multiple)

**User Experience**:
- Seamless navigation between Home and Game views
- Map stays centered when places are already loaded
- Faster view transitions (no loading delay)

**Technical Details**:
- Module-level refs are shared across all components
- First component to mount triggers fetch
- Subsequent components reuse existing data
- fetchPromise prevents concurrent fetches

---

## Modern Authentication Flow (October 21, 2025)

**Decision**: Replace modal-based auth with dedicated login/signup pages using modern form patterns.

**Implementation**:
1. **Dedicated Pages**: Separate `/login` and `/signup` routes
   - Better UX than modal interruption
   - Cleaner routing and state management
   - Follows modern SPA patterns

2. **Form Validation**: vee-validate + Zod for type-safe validation
   - Consistent with shadcn-vue ecosystem
   - Better TypeScript integration
   - Real-time validation feedback
   - Password confirmation on signup

3. **Email Verification**: Required before first login
   - `enable_confirmations = true` in Supabase
   - Clear messaging to check email after signup
   - Helpful error messages if trying to login without verification
   - Environment-aware redirect URLs (localhost:5173 for dev)

4. **Router Guards**: Navigation guards protect routes
   - `/game` requires authentication
   - `/login` and `/signup` redirect authenticated users to `/game`
   - Centralized auth logic (no per-component checks)

5. **Auth Store Improvements**: Better error handling
   - Specific error messages for common cases (email not confirmed, invalid credentials)
   - User-friendly wording instead of raw Supabase errors

**Rationale**:
- Dedicated pages provide better UX than modal interruption
- shadcn-vue form patterns match rest of application
- Email verification adds security layer
- Router guards centralize auth logic (DRY principle)
- Follows Vue Router best practices

**User Flow**:
1. New user clicks "Get Started" → redirects to `/login`
2. User clicks "Sign up" → goes to `/signup`
3. After signup → redirects to `/login` with "check your email" message
4. User verifies email via link in inbox
5. User signs in → redirects to `/game`
6. Future visits: authenticated users go directly to game

**Technical Benefits**:
- Cleaner component separation (no auth modal in game view)
- Better testability (isolated auth pages)
- Easier to extend (add password reset, OAuth, etc.)
- Matches modern web app patterns users expect

---

## UI Redesign - Playful & Fun Game Interface (October 21, 2025)

**Decision**: Complete UI redesign using shadcn-vue components with playful, game-like aesthetic.

**Design Direction**: Playful & Fun
- Rounded corners (increased border-radius from 0.625rem to 0.75rem)
- Vibrant blue primary color (oklch(0.55 0.22 250))
- Purple accent color for contrast (oklch(0.95 0.05 300))
- Smooth animations and transitions
- Gradient backgrounds on hero elements
- Enhanced shadows for depth (layered shadows)

**New Components Added**:

1. **ConfidenceBadge** (`src/components/ConfidenceBadge.vue`)
   - Reusable component for displaying confidence scores
   - Color-coded: High (green), Medium (yellow), Low (outline)
   - Integrated tooltip with explanations
   - Uses shadcn-vue Badge + Tooltip components

2. **AppSidebar** (`src/components/AppSidebar.vue`)
   - Collapsible sidebar with icon mode
   - User profile with avatar (initials from email)
   - Navigation menu (Home, Play Game)
   - Stats placeholder for future features
   - Theme toggle in footer
   - Sign out button
   - Uses shadcn-vue Sidebar component suite

3. **ThemeToggle** (`src/components/ThemeToggle.vue`)
   - Dropdown menu with Light/Dark/System options
   - Animated sun/moon icons
   - Uses @vueuse/core for theme persistence
   - Integrates with shadcn-vue DropdownMenu

4. **useTheme** composable (`src/composables/useTheme.ts`)
   - Wraps @vueuse/core's useColorMode
   - Provides reactive theme state
   - LocalStorage persistence
   - System preference detection

**Component Updates**:

1. **HeroCard**:
   - Gradient background (blue → purple)
   - Larger title with globe icon
   - Enhanced shadow and animations
   - Slide-up fade-in animation

2. **QuestionCard**:
   - Progress bar showing question progress (X/Y)
   - ConfidenceBadge for top match
   - Removed plain percentage display
   - Added transition animations on buttons

3. **ResultCard**:
   - Collapsible match analysis (default closed for high confidence)
   - Progress bars for semantic and spatial scores
   - ConfidenceBadge for overall match
   - Icons on all buttons for better UX
   - Enhanced visual hierarchy

4. **GameView**:
   - Wrapped in SidebarProvider + SidebarInset
   - AppSidebar integration
   - Sidebar toggle button (mobile-first)
   - Enhanced start screen with icons
   - Better spacing and typography
   - Shows all places on map when starting (same as HomeView)

5. **HomeView**:
   - Theme toggle in top-right corner
   - Same gradient hero card

**CSS Enhancements** (`src/style.css`):

1. **Custom Animations**:
   - `slide-up-fade`: Card entrance animation (0.4s ease-out)
   - `pulse-marker`: Map marker pulse (2s infinite)
   - `celebrate`: Success celebration (0.6s ease-in-out)

2. **Custom Shadows**:
   - `.shadow-playful-sm`: Subtle layered shadow
   - `.shadow-playful-lg`: Prominent layered shadow
   - Dark mode variants with adjusted opacity

3. **Gradient Utilities**:
   - `.bg-gradient-playful`: Blue → purple gradient
   - Separate dark mode variant

4. **Transition Utilities**:
   - `.transition-playful`: Smooth 0.3s cubic-bezier transitions
   - Hover effect: translateY(-2px)

5. **Dark Mode Support**:
   - Complete dark theme color palette
   - Vibrant colors maintained in dark mode
   - Proper contrast ratios
   - Success/Warning/Info colors for both modes

**New Dependencies**:
- `@vueuse/core`: Theme management
- `@iconify/vue`: Icon rendering
- `@iconify-json/radix-icons`: Icon library
- `tw-animate-css`: Animation utilities
- shadcn-vue components: badge, progress, sidebar, tooltip, collapsible, avatar, separator, dropdown-menu

**User Experience Improvements**:
- More engaging, game-like interface
- Better visual feedback (progress bars, badges, icons)
- Reduced cognitive load (collapsible details)
- Dark mode for accessibility
- Smooth, delightful micro-animations
- Better mobile experience with collapsible sidebar
- Seamless navigation (shared places state)

**Technical Quality**:
- Consistent shadcn-vue component usage
- Reusable components (ConfidenceBadge)
- Proper TypeScript types
- Accessible (tooltips, ARIA labels, proper color contrast)
- Maintainable (clear component structure)
- All tests passing (10/10)
- Type-check passing
- Lint passing

**Rationale**:
- Playful aesthetic matches game nature
- shadcn-vue provides consistent, accessible components
- Dark mode is increasingly expected by users
- Animations enhance perceived performance and delight
- Sidebar provides better navigation structure for future features
- Progressive disclosure (collapsible) reduces overwhelm

---

## Unit Test Isolation (October 21, 2025)

**Problem**: Unit tests were hitting real Supabase API during test runs.

**Discovery**: Tests were mocking `global.fetch` but composable uses `supabase.functions.invoke()`, which wasn't mocked.

**Solution**: Proper module mocking of `@/lib/supabase`
```typescript
vi.mock('@/lib/supabase', () => ({
  supabase: {
    functions: {
      invoke: vi.fn(),
    },
  },
}))
```

**Impact**:
- Tests now run in complete isolation (no network calls)
- Faster test execution
- Deterministic results (no flaky tests from API issues)
- Proper unit testing practices
- **10/10 tests passing** (was 4/10 before fix)

**Lesson**: Always mock external dependencies at module level, not at lower-level primitives (fetch vs. SDK methods).

---

## Pre-Deployment Polish

**Decision**: Comprehensive UX and security improvements before production deployment.

**Changes Implemented**:
1. **Toast Notifications**: Replaced all `alert()` with shadcn-vue Sonner toasts
   - Better UX, dismissible, non-blocking
   - Success/error variants with descriptions
   
2. **Input Validation**: 10-500 character limits with real-time feedback
   - Prevents empty/meaningless descriptions
   - Avoids token limit issues with Edge Function
   - Character counter provides visual feedback

3. **Rate Limiting**: Client-side protection (2-second cooldown, 50 requests/session)
   - Prevents accidental API abuse
   - User-friendly error messages
   - Note: Server-side rate limiting recommended for production

4. **Loading States**: Enhanced with spinner overlay and descriptive messages
   - "Analyzing your description..." during embedding generation
   - Improves perceived performance

5. **Accessibility**: ARIA labels on interactive map markers
   - `role="button"` and `aria-label` attributes
   - Reka UI provides built-in accessibility for all components

6. **Code Quality**: Fixed TypeScript recursion error, extracted constants, added JSDoc
   - TS2589 fixed with explicit type annotations
   - Magic numbers moved to configuration constants
   - Comprehensive documentation for complex functions

**Rationale**: Balanced polish for week-long deployment timeline. Focused on user experience, security, and code quality without over-engineering.

---

## Reduce MAX_QUESTIONS to 5

**Decision**: Reduce maximum questions per game from 10 to 5.

**Context**: Testing showed 1-2 questions sufficient for well-described places with good embeddings.

**Result**: Faster, more engaging games without sacrificing accuracy.

---

## Question Flow After Wrong Guess

**Decision**: Require at least one question after rejecting a high-confidence guess.

**Problem**: Users rejecting initial guesses saw immediate second guesses without engagement.

**Solution**: State machine enforces question before next guess via `mustAskQuestion` flag.

**Benefits**:
- Better user engagement
- Collects more learning data
- Gives system chance to narrow candidates

---

## Vector Embeddings Over Descriptors

**Decision**: Use full vector embeddings (384D gte-small) instead of simple descriptor filtering.

**Rationale**:
- More accurate semantic matching
- Handles creative/ambiguous descriptions
- Enables true learning from player descriptions
- Provides confidence scores for intelligent guessing

**Trade-offs**:
- More complex implementation (Edge Function required)
- Slightly higher latency
- Acceptable for significantly better accuracy (87-100% on clear descriptions)

---

## Confidence Threshold (70%)

**Decision**: Set `MIN_CONFIDENCE = 0.7` for showing guesses without questions.

**Rationale**:
- Balance between accuracy and user experience
- Lower threshold → too many wrong guesses
- Higher threshold → unnecessary questions
- 70% proven reliable in testing

---

## Cold Start with Seed Data

**Decision**: Include 20 famous places as seed data.

**Trade-off**: Violates pure "cold start" principle but provides better first-time experience and demonstrates capabilities immediately.

**Status**: Acceptable for MVP, system designed to grow organically from player contributions.
