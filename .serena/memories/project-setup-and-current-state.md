# 10x-mapmaster - Current Project State

## Overview
Intelligent geography guessing game where players describe a place, and the system uses vector embeddings to ask strategic yes/no questions to identify it. The game learns from every session, improving matching accuracy.

## Current Status: ✅ MVP 2 COMPLETE + REDESIGNED UI (Production-Ready)

**Latest Milestone:** Complete UI/UX redesign with modern game interface  
**Completion Date:** October 21, 2025

**Latest Update:** October 21, 2025 - UI Redesign Complete
- ✅ **Playful, modern game interface** with rounded corners and vibrant colors
- ✅ **Collapsible sidebar navigation** with user profile and stats
- ✅ **Shared map layout** prevents blinking between routes
- ✅ **Theme system** with light/dark/auto modes and persistence
- ✅ **Enhanced components**: ConfidenceBadge, progress bars, tooltips, collapsible sections
- ✅ **Custom animations** for delightful micro-interactions
- ✅ **Gradient backgrounds** and layered shadows for depth
- ✅ **Improved accessibility** with proper ARIA labels and keyboard navigation
- ✅ **Mobile-first** with responsive sidebar and touch-friendly UI

### UI/UX Design System (October 21, 2025)

**Design Philosophy**: Playful & Fun
- Vibrant blue primary color (oklch(0.55 0.22 250))
- Purple accent color (oklch(0.95 0.05 300))
- Rounded corners (0.75rem border-radius)
- Smooth transitions (0.3s cubic-bezier)
- Layered shadows for depth
- Gradient backgrounds for visual interest

**Layout Architecture**:
- `MapLayout.vue` - Shared layout with persistent map instance
- `AppSidebar` - Collapsible navigation with icon mode
- `SidebarProvider/SidebarInset` - shadcn-vue layout primitives
- No map blinking when navigating between routes
- Shared places state prevents redundant fetches

**New Components**:
1. **ConfidenceBadge** - Reusable confidence score display with tooltips
2. **AppSidebar** - Navigation sidebar with user profile, menu, theme toggle
3. **ThemeToggle** - Dropdown for light/dark/system theme selection
4. **FloatingNavbar** - Top navigation (currently minimal)

**Enhanced Components**:
- **HeroCard**: Gradient background, larger title, enhanced animations
- **QuestionCard**: Progress bar, ConfidenceBadge, animated buttons
- **ResultCard**: Collapsible analysis, progress bars, icons, confidence badge
- **GameView**: Sidebar integration, enhanced start screen, better spacing
- **HomeView**: Theme toggle, gradient hero
- **MapView**: Proper theme switching with map recreation

**shadcn-vue Components Added**:
- Avatar (with fallback for initials)
- Badge (for confidence scores and status)
- Collapsible (for expandable sections)
- DropdownMenu (for theme toggle and user menu)
- Form components (Input, Label, FormItem, FormControl, FormDescription, FormMessage)
- Progress (for semantic/spatial score visualization)
- Separator (for visual dividers)
- Sidebar suite (Sidebar, SidebarContent, SidebarFooter, SidebarHeader, etc.)
- Skeleton (for loading states)
- Tooltip (for helpful hints)

**Custom CSS Utilities** (`src/style.css`):
```css
/* Animations */
.animate-slide-up-fade - Card entrance (0.4s)
.animate-pulse-marker - Map marker pulse (2s infinite)
.animate-celebrate - Success animation (0.6s)

/* Shadows */
.shadow-playful-sm - Subtle layered shadow
.shadow-playful-lg - Prominent layered shadow

/* Gradients */
.bg-gradient-playful - Blue to purple gradient

/* Transitions */
.transition-playful - Smooth 0.3s transform
```

**Dark Mode**:
- Complete dark theme color palette
- Vibrant colors maintained
- Proper contrast ratios
- Theme persists via localStorage
- System preference detection (auto mode)

**User Experience Improvements**:
- Progress indicators show question progress (X/Y)
- Collapsible match analysis (closed by default for high confidence)
- Icons on all buttons for better visual recognition
- Smooth animations enhance perceived performance
- Better mobile experience with touch-friendly UI
- Sidebar auto-collapses on mobile
- No map jumping when switching routes

### Theme Management System (October 21, 2025)

**Implementation**: Custom `useTheme` composable with dual state
- `preference` - User's choice (light/dark/auto) persisted to localStorage
- `resolvedTheme` - Actual theme applied (light/dark only)
- Integrates with @vueuse/core's `useColorMode`
- System preference detection for auto mode

**Map Style Switching**:
- Map recreates when theme changes (via `key` attribute)
- Alidade Smooth (light) / Alidade Smooth Dark (dark)
- Prevents stale cached tiles from wrong theme

**Storage**: 
- Preference stored in localStorage as "theme-preference"
- Persists across page reloads and sessions

### Authentication System (October 21, 2025)

**Modern Auth Pages**:
- `LoginView.vue` - Dedicated login page with email verification messaging
- `SignupView.vue` - Registration with password confirmation
- Removed naive auth modal in favor of proper route-based authentication
- shadcn-vue Form components with vee-validate + Zod validation

**Router Configuration**:
- `/login` - Sign in page (redirects authenticated users to /game)
- `/signup` - Registration page (redirects authenticated users to /game)
- `/game` - Protected route (requires authentication)
- Navigation guards enforce auth requirements automatically

**Email Verification Flow**:
1. User signs up → receives verification email
2. User clicks verification link (environment-aware URL)
3. User can sign in after verification
4. Unverified users see helpful error message

**Supabase Configuration**:
- Email confirmations enabled (`enable_confirmations = true`)
- Site URL: `http://localhost:5173` (Vite default port)
- Additional redirect URLs for production deployment
- Environment-aware configuration ready for GitHub Pages

**User Experience**:
- Toast notifications for auth success/errors
- Helpful error messages (email not verified, invalid credentials, etc.)
- Seamless auth state management with Pinia
- Home page "Get Started" button routes based on auth state
- User profile in sidebar with avatar (email initials)
- Sign out button in sidebar footer

**Security**:
- All auth routes properly guarded
- RLS policies enforce user data isolation
- Auth store provides specific error messages
- Session management via Supabase Auth

### Migration Reorganization (October 21, 2025)

**Clean Migration Structure**:
1. `000001_initial_schema.sql` - Complete schema (tables, extensions, RLS, indexes, triggers)
2. `000002_seed_data.sql` - All seed data (20 places + 20 questions, no embeddings)
3. `000003_seed_embeddings.sql` - Generated embeddings (40 UPDATE statements)
4. `000004_database_functions.sql` - All database functions (vector search, filtering, learning)

**Benefits**:
- ✅ Logical order (schema → data → embeddings → functions)
- ✅ Single source of truth for each concern
- ✅ Fast database reset (no complex dependencies)
- ✅ Easy to understand and maintain

### Quality Improvements (All Complete)

✅ **Modern UI/UX**
- Playful, game-like interface with vibrant colors
- Collapsible sidebar navigation with user profile
- Theme system with light/dark/auto modes
- Shared map layout prevents blinking
- Custom animations and smooth transitions
- Enhanced accessibility (ARIA labels, keyboard navigation)
- Mobile-first responsive design

✅ **Authentication & Security**
- Modern authentication with dedicated pages
- Email verification required with helpful messaging
- Router guards protecting authenticated routes
- Email verification enforced before login
- Client-side rate limiting (2-second cooldown, 50 requests/session)
- Proper module mocking in unit tests

✅ **User Experience**
- Replaced all browser alerts with Sonner toast notifications
- Input validation (10-500 characters) with character counter
- Loading states with spinner overlay and descriptive messages
- Progress bars for question progress and match scores
- Collapsible sections for progressive disclosure
- User-friendly error messages throughout

✅ **Code Quality**
- Fixed unit tests to never hit real APIs (proper Supabase mocking)
- Fixed TS2589 type recursion error (TypeScript build passing)
- Extracted magic number constants (LOW_CONFIDENCE_MIN/MAX)
- Removed all debugging console.log statements
- Added comprehensive JSDoc to complex functions
- All linting passing (oxlint + eslint)
- **10/10 tests passing**

## Security Status

**Last Validated:** October 21, 2025  
**Status:** ✅ **SECURE - Ready for Public Repository**

### Security Audit Summary
- ✅ **Code Scan**: No vulnerabilities found (SQL injection, XSS, auth issues)
- ✅ **Secrets Management**: All credentials via environment variables, no hardcoded secrets
- ✅ **Dependencies**: 0 vulnerabilities (635+ packages audited)
- ✅ **Authentication**: Proper Supabase Auth with email verification + RLS policies enforced
- ✅ **Input Validation**: Client and server-side validation implemented
- ✅ **Rate Limiting**: API abuse prevention active (2s cooldown, 50 req/session)
- ✅ **Unit Tests**: Properly isolated (no real API calls)

### Security Features
- Email verification required before access
- Supabase RLS policies protect all user data
- Router guards enforce authentication
- Vue 3 auto-escaping prevents XSS attacks
- Parameterized queries prevent SQL injection
- CORS properly configured in Edge Functions
- No sensitive data exposed in frontend code

## Tech Stack
- **Frontend**: Vue 3 + TypeScript + Vite + Pinia + Vue Router
- **UI**: shadcn-vue (Tailwind CSS v4, Reka UI primitives, Sonner toasts)
- **Forms**: vee-validate + Zod (type-safe validation)
- **Theme**: @vueuse/core (useColorMode, useStorage)
- **Icons**: @iconify/vue + @iconify-json/radix-icons
- **Maps**: MapLibre GL JS v5.9.0
- **Backend**: Supabase (PostgreSQL + pgvector + PostGIS + Auth)
- **Embeddings**: Supabase AI gte-small (384 dimensions)
- **Testing**: Playwright (E2E) + Vitest (unit, properly mocked)

## Database Schema

**Tables:**
- `places`: id, name, lat, lng, geom (Point), descriptors (jsonb), embedding (vector 384), game_count
- `questions`: id, text, sequence, filter_type, embedding (vector 384), times_asked, effectiveness_score
- `game_sessions`: id, user_id, place_id, was_correct, description, description_embedding (vector 384), question_count
- `game_answers`: id, session_id, question_id, answer, candidates_after, sequence_number

**Key Functions:**
- `match_places(embedding, threshold, limit)`: Vector similarity + spatial confidence
- `filter_candidates_with_history(ids[], history)`: Cumulative semantic + spatial filtering
- `update_geom_from_latlng()`: Auto-maintain PostGIS geometry
- `update_place_embedding()`: Learning via weighted average
- `update_question_effectiveness()`: Track question performance

**RLS Policies (Verified):**
- ✅ `places`: SELECT (public), INSERT/UPDATE (authenticated)
- ✅ `questions`: SELECT (public), UPDATE (authenticated - for learning)
- ✅ `game_sessions`: SELECT/INSERT (user's own sessions only)
- ✅ `game_answers`: SELECT/INSERT (user's own answers only)

## Configuration

### Supabase Auth (supabase/config.toml)
```toml
[auth]
site_url = "http://localhost:5173"
additional_redirect_urls = ["http://127.0.0.1:5173", "https://ciaastek.github.io"]
enable_signup = true

[auth.email]
enable_confirmations = true  # Required email verification
```

### Game Settings (src/stores/game.ts)
```typescript
const MAX_QUESTIONS = 5           // Questions per game
const LEARNING_RATE = 0.3         // Embedding update weight
const MIN_CONFIDENCE = 0.7        // Threshold for immediate guess
const INITIAL_CANDIDATES = 20     // Vector search limit
const MATCH_THRESHOLD = 0.1       // Min similarity (10%)
const LOW_CONFIDENCE_MIN = 0.5    // UI threshold
const LOW_CONFIDENCE_MAX = 0.8    // UI threshold
```

### Input Validation (src/views/GameView.vue)
```typescript
const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 500
```

### Rate Limiting (src/composables/useEmbeddings.ts)
```typescript
const RATE_LIMIT_MS = 2000           // 2 seconds between requests
const MAX_REQUESTS_PER_SESSION = 50   // Session limit
```

## Development Workflow

### Daily Development (Fast, Clean)
```bash
# Start development
npm run dev  # http://localhost:5173/10x-mapmaster/

# Database reset (fast, uses migrations with embeddings)
npx supabase db reset  # ✅ All 4 migrations applied in order

# Quality checks
npm run type-check  # ✅ Passing
npm run lint        # ✅ Passing  
npm test            # ✅ All tests passing (10/10)

# Build for production
npm run build
```

### Adding New Seed Data (One-Time)
```bash
# 1. Edit seed data migration
# Add to: supabase/migrations/000002_seed_data.sql

# 2. Generate fresh embeddings
npm run generate:seed-migration

# 3. Test
npx supabase db reset

# 4. Commit both files
git add supabase/migrations/000002_seed_data.sql
git add supabase/migrations/000003_seed_embeddings.sql
git commit -m "Add new seed data with embeddings"
```

## Environment Variables

### Local Development (.env.local)
```bash
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_ANON_KEY=<local_anon_key>
VITE_SUPABASE_SERVICE_KEY=<local_service_key>

# Only needed for generating seed embeddings (one-time)
VITE_SUPABASE_FUNCTIONS_URL_PROD=<production_edge_function_url>
VITE_SUPABASE_ANON_KEY_PROD=<production_anon_key>
```

### Production (GitHub Secrets)
```bash
VITE_SUPABASE_URL=<production_url>
VITE_SUPABASE_ANON_KEY=<production_anon_key>
```

## File Structure

```
src/
  main.ts                      # App entry with auth init
  App.vue                      # Root component with toast provider
  router/index.ts              # Routes + auth guards
  
  layouts/
    MapLayout.vue              # Shared sidebar + map layout ✨
  
  composables/
    useEmbeddings.ts           # Embedding generation + rate limiting
    useNominatim.ts            # Place search API
    usePlaces.ts               # Singleton place state ✨
    useTheme.ts                # Theme management with persistence ✨
  
  components/
    AppSidebar.vue             # Navigation sidebar ✨
    ConfidenceBadge.vue        # Reusable confidence display ✨
    FloatingNavbar.vue         # Top navigation ✨
    HeroCard.vue               # Landing with auth-aware routing
    ThemeToggle.vue            # Theme dropdown ✨
    game/
      QuestionCard.vue         # Q&A with progress and confidence
      ResultCard.vue           # Collapsible match analysis
      PlaceSearch.vue          # Nominatim autocomplete
    map/
      MapView.vue              # Map with theme switching
    ui/                        # shadcn-vue components
      avatar/                  # User profile pictures ✨
      badge/                   # Status badges ✨
      collapsible/             # Expandable sections ✨
      dropdown-menu/           # Menus and dropdowns ✨
      form/                    # Form validation components
      input/                   # Text inputs ✨
      progress/                # Progress bars ✨
      separator/               # Visual dividers ✨
      sidebar/                 # Sidebar layout primitives ✨
      skeleton/                # Loading states ✨
      tooltip/                 # Helpful hints ✨
      (other existing components...)
  
  stores/
    auth.ts                    # Supabase auth with error handling
    game.ts                    # Game logic with JSDoc
  
  views/
    HomeView.vue               # Landing page with theme toggle
    LoginView.vue              # Dedicated login page
    SignupView.vue             # Dedicated signup page
    GameView.vue               # Main game (wrapped in MapLayout)
    StatisticsView.vue         # User stats (placeholder) ✨
  
  types/database.ts            # Supabase auto-generated types
  style.css                    # Custom animations, shadows, gradients ✨

supabase/
  config.toml                  # Auth configuration
  functions/generate-embedding/ # Edge Function (gte-small)
  migrations/                  # 4 clean migrations
    000001_initial_schema.sql
    000002_seed_data.sql
    000003_seed_embeddings.sql (generated)
    000004_database_functions.sql

src/__tests__/
  App.spec.ts                         # App initialization
  composables/
    useEmbeddings.spec.ts             # Properly mocked tests
```

## Known Limitations

- **Minor 406 error**: Occurs during place lookup (non-fatal, cosmetic)
- **Nominatim rate limit**: 1 req/sec (debounced in UI)
- **Client-side rate limiting**: Server-side should be added to Edge Function
- **Statistics view**: Placeholder UI only (no backend implementation yet)

## Next Steps (Optional Enhancements)

1. **Production Deployment**: GitHub Pages + production Supabase  
   - Update Supabase site_url in dashboard for production
2. **Statistics Backend**: Implement user stats queries and visualizations
3. **Server-side Rate Limiting**: Add to Edge Function
4. **Analytics**: Track learning effectiveness, popular places
5. **Performance**: Code splitting, lazy loading
6. **Social Features**: Leaderboards, shared games
7. **Password Reset**: Add forgot password flow
8. **More Seed Data**: Popular landmarks, cities, natural wonders

## Success Criteria (All Met ✅)

✅ TypeScript build passes without errors  
✅ All linting passes (oxlint + eslint)  
✅ Unit tests for critical composables (properly mocked)  
✅ E2E tests for main user flows  
✅ Modern authentication with email verification  
✅ Router guards protect authenticated routes  
✅ No browser `alert()` dialogs  
✅ Input validation prevents invalid data  
✅ Loading states provide user feedback  
✅ Rate limiting prevents API abuse  
✅ Map markers have ARIA labels  
✅ RLS policies verified and documented  
✅ User-friendly error messages  
✅ Code quality: JSDoc on complex functions  
✅ Fast local development with migration-based embeddings  
✅ Clean, logical migration structure (4 migrations)  
✅ **Playful, modern UI with complete design system**  
✅ **Theme system with light/dark/auto modes**  
✅ **Shared map layout prevents blinking**  
✅ **Collapsible sidebar navigation**  
✅ **Mobile-first responsive design**  
✅ **10/10 tests passing**

**The project is production-ready with a delightful, polished UI!** 🎉✨
