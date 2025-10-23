# Design: Architecture & Major Decisions

## Core Architectural Decisions

### Session-First Architecture (October 22, 2025)

**Core Concept:** Database is source of truth. Game session created immediately, all state derived from relations.

**Schema Design:**
- `game_answers` table refactored with `answer_type` enum (question_answer, wrong_guess)
- `game_sessions` simplified (nullable place_id, was_correct flag)
- `game_session_stats` view for computed statistics

**Database Functions:**
1. `get_candidates(session_id)` - Session-aware candidate retrieval
2. `update_question_effectiveness_batch(session_id)` - Batch learning

**Benefits:**
- Game state survives page refreshes
- Enables game replay/analysis
- Provides learning data
- Simplifies frontend state management
- No ephemeral state to keep in sync

**Rationale:** Database is better at relational queries and provides single source of truth. Frontend only needs to read and display.

---

### Algorithmic Filtering Architecture (October 23, 2025)

**Decision:** Remove all hardcoded question filters, implement pure algorithmic approach using pgvector + PostGIS only.

**Context:**
- Original system had 40+ lines of hardcoded CASE WHEN statements
- Explicit field checks: `descriptors->>'class' = 'natural'`, `descriptors->>'is_capital_city'`
- String matching for routing: `q.value->>'question' = 'Is it in a capital city?'`
- Silent failures when fields missing (ELSE TRUE fallback)
- Required code changes + deployment to add new questions

**New Architecture - Two Pure Filters:**

1. **Geographic Filtering** - PostGIS bbox intersection (ST_Within)
   - YES answers: candidate must be WITHIN bbox
   - NO answers: candidate must be OUTSIDE bbox
   - No hardcoded country/region checks

2. **Semantic Filtering** - pgvector cosine similarity
   - Calculate similarity between place and answered questions
   - YES answers: boost confidence by similarity score
   - NO answers: penalize confidence by similarity score
   - Boost weight: 0.3 (adjustable)

**Implementation:**
```sql
-- Geographic: Pure spatial operations
WHERE NOT EXISTS (
  SELECT 1 FROM answered_geographic
  WHERE (answer = YES AND NOT ST_Within(place, bbox))
     OR (answer = NO AND ST_Within(place, bbox))
)

-- Semantic: Pure vector similarity
semantic_boost = AVG(
  CASE 
    WHEN answer = YES THEN (1 - place_emb <=> question_emb)
    ELSE -(1 - place_emb <=> question_emb)
  END
) * 0.3
```

**Test Results:**
- Mount Fuji: Guessed immediately (83% confidence) ✅
- Machu Picchu: 2 questions, 15→2 candidates (87% reduction) ✅
- Geographic filtering: Perfect bbox intersection ✅
- Semantic adjustment: Confidence boost/penalty working ✅

**Benefits:**
- ✅ Zero hardcoded filters
- ✅ Adding questions = INSERT only (no code changes)
- ✅ Scales to infinite questions
- ✅ Geographic questions now visible (0.6 baseline score)
- ✅ No silent failures
- ✅ Pure ML/AI system

**Trade-offs:**
- Requires good place embeddings (future: rich enrichment)
- Semantic matching depends on embedding quality
- Slightly more complex SQL (but more maintainable)

**Rationale:** System should learn from embeddings, not hardcoded rules. Questions are data, not code. Future enrichment will add context like "Eiffel Tower in Paris, capital of France" so questions like "capital city" work naturally via semantic similarity.

---

### Vector Embeddings Over Descriptors

**Decision:** Use full vector embeddings (384D gte-small) instead of simple descriptor filtering.

**Rationale:**
- More accurate semantic matching
- Handles creative/ambiguous descriptions
- Enables true learning from player descriptions
- Provides confidence scores for intelligent guessing

**Trade-offs:**
- More complex implementation (Edge Function required)
- Slightly higher latency (~500ms)
- Acceptable for significantly better accuracy (87-100% on clear descriptions)

**Model Choice: gte-small**
- 384 dimensions (vs 768 for sentence-transformers)
- Good balance of accuracy and performance
- Built into Supabase (no external service)
- Cost-effective for MVP scale

---

### Per-Place Spatial Confidence (October 22, 2025)

**Implementation:** Calculate spatial confidence individually per place based on distance from candidate set centroid.

**Formula:** `1 - (distance_to_centroid / max_distance)`

**Rationale:** Places closer to the cluster center are more likely to be the target than outliers.

**Location:** Lines 263-282 in `supabase/migrations/000003_database_functions.sql`

---

## Game Design Decisions

### Maximum Questions: 5

**Decision:** Reduce maximum questions per game from 10 to 5.

**Context:** Testing showed 1-2 questions sufficient for well-described places with good embeddings.

**Result:** Faster, more engaging games without sacrificing accuracy.

**Configurable:** `MAX_QUESTIONS = 5` in game store

---

### Confidence Threshold: 70%

**Decision:** Set `MIN_CONFIDENCE = 0.7` for showing guesses without questions.

**Rationale:**
- Balance between accuracy and user experience
- Lower threshold → too many wrong guesses
- Higher threshold → unnecessary questions
- 70% proven reliable in testing

**Configurable:** `MIN_CONFIDENCE = 0.7` in game store

---

### Question Flow After Wrong Guess

**Decision:** Require at least one question after rejecting a high-confidence guess.

**Problem:** Users rejecting initial guesses saw immediate second guesses without engagement.

**Solution:** State machine enforces question before next guess via `mustAskQuestion` flag.

**Benefits:**
- Better user engagement
- Collects more learning data
- Gives system chance to narrow candidates
- Prevents guess spam

---

### Cold Start with Seed Data

**Decision:** Include 20 famous places as seed data.

**Trade-off:** Violates pure "cold start" principle but provides better first-time experience and demonstrates capabilities immediately.

**Status:** Acceptable for MVP, system designed to grow organically from player contributions.

**Seed Places:**
- Diverse geographic distribution
- Mix of natural and man-made landmarks
- Well-known globally
- Good for testing vector similarity

---

## Frontend Architecture Decisions

### Shared Map Layout (October 21, 2025)

**Problem:** Map was blinking/recreating when navigating between HomeView and GameView.

**Root Cause:** Each view had its own `<MapView>` component that was unmounted/mounted on route change.

**Solution:** Create shared `MapLayout.vue` that wraps both views with single persistent map instance.

**Implementation:**
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

**Benefits:**
- ✅ Single map instance persists across routes (no blinking)
- ✅ Centralized sidebar + map structure
- ✅ Views focus only on overlay content
- ✅ Map candidates update reactively based on route and game state
- ✅ Better performance (no map re-initialization)

---

### Shared Places State - Singleton Pattern (October 21, 2025)

**Problem:** Places were being fetched separately in HomeView and GameView, causing map to reload and jump when navigating between views.

**Solution:** Convert `usePlaces` composable to singleton pattern with shared state.

**Implementation:**
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

**Benefits:**
- Places fetched only once per session
- No map jumping when switching views
- Shared reactive state across components
- Prevents race conditions (multiple simultaneous fetches)
- Better performance (one network request instead of multiple)

**Pattern:** Module-level state shared across all composable instances

---

### Theme Management - Proper Persistence (October 21, 2025)

**Problem:** Theme preference wasn't persisting to localStorage, and map styles weren't switching when theme changed.

**Root Causes:**
1. `useColorMode` returns resolved theme (light/dark), not user preference (light/dark/auto)
2. MapLibre component doesn't react to `:map-style` prop changes
3. No separation between user preference and resolved theme

**Solution:** Custom theme composable with dual state management

**Implementation:**
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

**Map Style Switching:**
Used Vue's `key` attribute to force map recreation when theme changes:
```vue
<MglMap
  :key="mapStyle"
  :map-style="mapStyle"
  ...
/>
```

**Why `key` works:**
- Vue destroys and recreates component when `key` changes
- `mapStyle` computed returns different URL for each theme
- Simpler than manually calling MapLibre's `setStyle()` method
- No need to track map instance or watch for changes

**Benefits:**
- ✅ Theme preference persists across page reloads
- ✅ System theme (auto) works correctly
- ✅ Map recreates with correct Alidade style (Smooth / Smooth Dark)
- ✅ Clean separation of concerns (preference vs. resolved state)
- ✅ localStorage integration via `useStorage`

---

## Authentication Flow (October 21, 2025)

**Decision:** Replace modal-based auth with dedicated login/signup pages using modern form patterns.

**Implementation:**

1. **Dedicated Pages:** Separate `/login` and `/signup` routes
   - Better UX than modal interruption
   - Cleaner routing and state management
   - Follows modern SPA patterns

2. **Form Validation:** vee-validate + Zod for type-safe validation
   - Consistent with shadcn-vue ecosystem
   - Better TypeScript integration
   - Real-time validation feedback
   - Password confirmation on signup

3. **Email Verification:** Required before first login
   - `enable_confirmations = true` in Supabase
   - Clear messaging to check email after signup
   - Helpful error messages if trying to login without verification
   - Environment-aware redirect URLs (localhost:5173 for dev)

4. **Router Guards:** Navigation guards protect routes
   - `/game` requires authentication
   - `/login` and `/signup` redirect authenticated users to `/game`
   - Centralized auth logic (no per-component checks)

5. **Auth Store Improvements:** Better error handling
   - Specific error messages for common cases (email not confirmed, invalid credentials)
   - User-friendly wording instead of raw Supabase errors

**Rationale:**
- Dedicated pages provide better UX than modal interruption
- shadcn-vue form patterns match rest of application
- Email verification adds security layer
- Router guards centralize auth logic (DRY principle)
- Follows Vue Router best practices

---

## UI Design System (October 21, 2025)

**Decision:** Complete UI redesign using shadcn-vue components with playful, game-like aesthetic.

### Design Direction: Playful & Fun
- Rounded corners (increased border-radius from 0.625rem to 0.75rem)
- Vibrant blue primary color (oklch(0.55 0.22 250))
- Purple accent color for contrast (oklch(0.95 0.05 300))
- Smooth animations and transitions
- Gradient backgrounds on hero elements
- Enhanced shadows for depth (layered shadows)

### New Components

**ConfidenceBadge** (`src/components/ConfidenceBadge.vue`)
- Reusable component for displaying confidence scores
- Color-coded: High (green), Medium (yellow), Low (outline)
- Integrated tooltip with explanations
- Uses shadcn-vue Badge + Tooltip components

**AppSidebar** (`src/components/AppSidebar.vue`)
- Collapsible sidebar with icon mode
- User profile with avatar (initials from email)
- Navigation menu (Home, Play Game)
- Stats placeholder for future features
- Theme toggle in footer
- Sign out button
- Uses shadcn-vue Sidebar component suite

**ThemeToggle** (`src/components/ThemeToggle.vue`)
- Dropdown menu with Light/Dark/System options
- Animated sun/moon icons
- Uses @vueuse/core for theme persistence
- Integrates with shadcn-vue DropdownMenu

### Component Updates

**HeroCard:**
- Gradient background (blue → purple)
- Larger title with globe icon
- Enhanced shadow and animations
- Slide-up fade-in animation

**QuestionCard:**
- Progress bar showing question progress (X/Y)
- ConfidenceBadge for top match
- Removed plain percentage display
- Added transition animations on buttons

**ResultCard:**
- Collapsible match analysis (default closed for high confidence)
- Progress bars for semantic and spatial scores
- ConfidenceBadge for overall match
- Icons on all buttons for better UX
- Enhanced visual hierarchy

**GameView:**
- Wrapped in SidebarProvider + SidebarInset
- AppSidebar integration
- Sidebar toggle button (mobile-first)
- Enhanced start screen with icons
- Better spacing and typography
- Shows all places on map when starting (same as HomeView)

### CSS Enhancements

**Custom Animations:**
- `slide-up-fade`: Card entrance animation (0.4s ease-out)
- `pulse-marker`: Map marker pulse (2s infinite)
- `celebrate`: Success celebration (0.6s ease-in-out)

**Custom Shadows:**
- `.shadow-playful-sm`: Subtle layered shadow
- `.shadow-playful-lg`: Prominent layered shadow
- Dark mode variants with adjusted opacity

**Gradient Utilities:**
- `.bg-gradient-playful`: Blue → purple gradient
- Separate dark mode variant

**Transition Utilities:**
- `.transition-playful`: Smooth 0.3s cubic-bezier transitions
- Hover effect: translateY(-2px)

**Dark Mode Support:**
- Complete dark theme color palette
- Vibrant colors maintained in dark mode
- Proper contrast ratios
- Success/Warning/Info colors for both modes

### User Experience Improvements
- More engaging, game-like interface
- Better visual feedback (progress bars, badges, icons)
- Reduced cognitive load (collapsible details)
- Dark mode for accessibility
- Smooth, delightful micro-animations
- Better mobile experience with collapsible sidebar
- Seamless navigation (shared places state)

**Rationale:**
- Playful aesthetic matches game nature
- shadcn-vue provides consistent, accessible components
- Dark mode is increasingly expected by users
- Animations enhance perceived performance and delight
- Sidebar provides better navigation structure for future features
- Progressive disclosure (collapsible) reduces overwhelm

---

## Pre-Deployment Polish (October 21, 2025)

**Decision:** Comprehensive UX and security improvements before production deployment.

**Changes Implemented:**

1. **Toast Notifications:** Replaced all `alert()` with shadcn-vue Sonner toasts
   - Better UX, dismissible, non-blocking
   - Success/error variants with descriptions

2. **Input Validation:** 10-500 character limits with real-time feedback
   - Prevents empty/meaningless descriptions
   - Avoids token limit issues with Edge Function
   - Character counter provides visual feedback

3. **Rate Limiting:** Client-side protection (2-second cooldown, 50 requests/session)
   - Prevents accidental API abuse
   - User-friendly error messages
   - Note: Server-side rate limiting recommended for production

4. **Loading States:** Enhanced with spinner overlay and descriptive messages
   - "Analyzing your description..." during embedding generation
   - Improves perceived performance

5. **Accessibility:** ARIA labels on interactive map markers
   - `role="button"` and `aria-label` attributes
   - Reka UI provides built-in accessibility for all components

6. **Code Quality:** Fixed TypeScript recursion error, extracted constants, added JSDoc
   - TS2589 fixed with explicit type annotations
   - Magic numbers moved to configuration constants
   - Comprehensive documentation for complex functions

**Rationale:** Balanced polish for week-long deployment timeline. Focused on user experience, security, and code quality without over-engineering.

---

## Key Technical Principles

1. **Database-Centric:** PostgREST pattern - DB does heavy lifting
2. **Session-First:** All game state in database relations
3. **Pure Algorithmic:** No hardcoded business logic
4. **Vector-Powered:** Semantic matching via embeddings
5. **Progressive Enhancement:** Rich features built on solid foundation
6. **Accessibility First:** ARIA labels, keyboard navigation, color contrast
7. **Mobile-Ready:** Responsive design, collapsible sidebar
8. **Performance:** Lazy loading, code splitting, singleton patterns
9. **Security:** RLS policies, email verification, input validation
10. **Maintainability:** Clear patterns, TypeScript strict mode, comprehensive tests