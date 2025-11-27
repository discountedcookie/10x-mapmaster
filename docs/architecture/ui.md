# UI Specification

## Design Philosophy

- **Conversational** - The game is a dialogue; UI reflects this with chat-like interaction
- **Map-centric** - Full viewport map is always visible, never remounted
- **Single panel** - One floating panel transforms content based on route
- **Seamless transitions** - Route changes animate smoothly without flicker
- **Unified layout** - Same structure across all routes and screen sizes

## Technology Stack

### Core

- Vue 3 with Composition API
- Vue Router for navigation
- shadcn-vue for component primitives
- Tailwind CSS for styling
- MapLibre GL JS for map rendering

### Enhancements

- @vueuse/core for utility composables (useColorMode, useMediaQuery)
- @vueuse/motion for declarative animations
- deck.gl for 3D extruded polygon markers (@deck.gl/core, @deck.gl/layers, @deck.gl/mapbox)
- Tolgee for translation management (i18n)
- Pinia for state management

## Responsive Design

Default Tailwind breakpoints, mobile-first approach. Layout structure identical across breakpoints - only sizing adjusts.

## Theme System

Three modes: Light, Dark, System (follows OS preference).

- Toggle cycles: Light  Dark  System  Light
- Map basemap switches with theme (Positron / Dark Matter)
- CSS variables define color tokens
- Glass morphism adapts to theme
- Theme choice is stored in `localStorage` only; it is never persisted in the database

## Architecture

### Single Map Instance

The map is rendered once at the layout level and never remounts. Route changes only update map parameters:

- Markers (places, candidates)
- Center position
- Zoom level
- Highlighted regions/polygons

This avoids expensive map reloads and provides seamless transitions.

### Layout Structure

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  [Logo]                        [Theme] [Avatar] │  ← Nav elements (floating)
│                                                 │
│            ┌───────────────────────┐            │
│            │                       │            │
│            │   RouterView          │            │  ← Panel (position varies)
│            │   (panel content)     │            │
│            │                       │            │
│            └───────────────────────┘            │
│                                                 │
│                 Map (persistent)                │
│                                                 │
└─────────────────────────────────────────────────┘
```

- Map and nav elements live in the root layout
- RouterView renders inside the floating panel
- Panel position/size controlled by route meta or state

### State Management

Application state organized by domain:

| Domain | Responsibilities                                 |
| ------ | ------------------------------------------------ |
| Auth   | User session, anonymous/registered status        |
| Game   | Active session, conversation history, candidates |
| Places | Known places for home map display                |
| UI     | Theme, panel position, loading states            |

State persists across route changes. Game state loads from API when navigating to /game/:id.

## Routing

### Routes

| Route              | Panel Position | Content                                       |
| ------------------ | -------------- | --------------------------------------------- |
| `/`                | Center         | Home - description input                      |
| `/game/:sessionId` | Corner         | Game - chat conversation                      |
| `/login`           | Center         | Login form                                    |
| `/signup`          | Center         | Signup form                                   |
| `/stats`           | Center         | User statistics and history (registered only) |
| `/stats/global`    | Center         | Global statistics overview                    |

### Deep Linking

- Active games shareable via `/game/:sessionId`
- Session ownership validated server-side (RLS)
- Invalid/expired sessions show error in panel

### Transitions

Route transitions synchronized with panel animations:

1. Route change triggered
2. Current content fades/slides out
3. Panel position animates (if changing)
4. New content fades/slides in

Navigation guards ensure:

- Auth routes redirect if already logged in
- Stats route redirects anonymous users to login
- Game route validates session exists

## Panel Behavior

### Position States

| Position | Used By                                  | Size                      |
| -------- | ---------------------------------------- | ------------------------- |
| Center   | Home, Login, Signup, Stats, Global Stats | Medium width, auto height |
| Corner   | Game                                     | Fixed width, max height   |

**Desktop corner:** Bottom-right, ~400px wide, ~60vh max height
**Mobile corner:** Bottom, full width, ~50vh height

### Content by Route

**Home (`/`)**

- Game title/logo
- Description text input
- Submit button
- Brief instructions or tagline

**Game (`/game/:sessionId`)**

- Chat message history (scrollable)
- Current turn indicator
- Input area (contextual: answer buttons, confirm buttons, or place search)

**Login (`/login`)**

- Email/password inputs (or OAuth buttons)
- Link to signup
- "Continue as guest" option

**Signup (`/signup`)**

- Registration form
- OAuth options
- Link to login

**Stats (`/stats`)**

- Summary metrics (games played, win rate, avg turns, places added) sourced from the `public.user_stats` view
- Game history list (infinite scroll over the user's `game_sessions`, ordered by most recent)
- Back/close action

**Global Stats (`/stats/global`)**

- Global metrics (total games, total places, total traits, overall win rate, avg turns to win) sourced from the `public.global_stats` view
- Optional additional aggregate charts or leaderboards (if desired in future)
- Back/close action

### Glass Morphism

Panel styling:

- Semi-transparent background
- Backdrop blur
- Subtle border
- Shadow for depth
- Adapts to light/dark theme

## Navigation Elements

Floating individually over map, not in a bar:

**Logo** (top-left)

- Links to home
- Small, unobtrusive

**Avatar Menu** (top-right)

Single menu accessed by clicking avatar/user icon. Contains submenus for settings:

```
┌─────────────────────┐
│ Theme          ▶   │ → Light / Dark / System
├─────────────────────┤
│ Language       ▶   │ → English / Polski / ...
├─────────────────────┤
│ Stats              │   (registered users only)
│ Sign out           │   (registered users only)
├─────────────────────┤
│ Sign in            │   (anonymous users only)
└─────────────────────┘
```

- Anonymous users: See Theme, Language, Sign in
- Registered users: See Theme, Language, Stats, Sign out
- Glass background on the menu
- Submenus for Theme and Language selection

**Language Selection**

- Detected from browser on first visit
- Stored in `localStorage` only; not persisted in the database
- Affects LLM-generated questions (passed as `language_code` to `start_game`)
- v1 languages: English (en), Polish (pl)
- Translations managed via Tolgee

## Chat Interface

### Message Types

**User messages (right-aligned, primary color):**

- Initial description
- Answer responses ("Yes", "No", "Not sure")

**System messages (left-aligned, muted color):**

- Questions about traits/regions
- Guesses: "Is it [Place Name]?"
- Results: success or failure
- Errors (distinct styling)

### Input Area

Contextual based on game state:

| Game State | Input Content                  |
| ---------- | ------------------------------ |
| Question   | Yes / No / Not Sure buttons    |
| Guess      | Yes / No buttons               |
| Give Up    | Place search with autocomplete |
| Won/Ended  | Play Again button              |

### Turn Indicator

Shows progress: current turn / max turns. Displayed in panel header or as subtle element.

### Candidate List

Displayed in the chat panel during active game, showing current candidates:

```
┌─────────────────────────────┐
│ Candidates                  │
├─────────────────────────────┤
│ 1. Eiffel Tower    ████████ │
│ 2. Big Ben         █████    │
│ 3. Colosseum       ███      │
│ 4. Taj Mahal       ██       │
└─────────────────────────────┘
```

Each entry shows:

- Rank number (by confidence)
- Place name
- Confidence bar (visual, no percentage)

Clicking a candidate could pan/zoom map to that location. List updates as candidates are eliminated or confidence changes. Complements the 3D pin markers on the globe (pin height = confidence).

## Map Visualization

### Globe View

The map uses MapLibre's globe projection throughout - no flat map. This creates a dramatic, unique visual for a geography game.

### Globe Behavior by State

| State       | Rotation                   | Camera                                      |
| ----------- | -------------------------- | ------------------------------------------- |
| Home (idle) | Slow auto-rotate           | Zoomed out, shows full globe                |
| Game active | No auto-rotate             | Auto-frames candidates, user can pan/rotate |
| Win/End     | Gentle orbit around winner | Zoomed to winning place                     |

### 3D Extruded Markers (deck.gl)

Candidate places are visualized as 3D extruded polygons using deck.gl's `PolygonLayer`. The place's actual polygon shape (from Nominatim/PostGIS) extrudes upward from the globe, with height representing confidence.

**Implementation:**

- **deck.gl PolygonLayer** with `extruded: true` for 3D extrusion
- **MapLibre integration** via `@deck.gl/mapbox` overlay
- **Smooth animations** via deck.gl's built-in `transitions`

**Polygon sources:**

- Places WITH geometry: Use actual polygon from Nominatim (landmark footprint, city boundary, etc.)
- Places WITHOUT geometry: Generate small circle polygon from point coordinates (consistent visual style)

**Visual states:**

| Candidate State  | Height               | Color          | Animation        |
| ---------------- | -------------------- | -------------- | ---------------- |
| Top candidate    | Tallest              | Primary + glow | Pulse            |
| Other candidates | By confidence        | Muted          | Subtle breathing |
| Eliminated       | Shrinks into surface | Fading         | Fade out         |

**Dependencies:** `@deck.gl/core`, `@deck.gl/layers`, `@deck.gl/mapbox`

### Polygon Visibility

Polygons appear based on zoom level and polygon size:

- Large polygons (countries, regions): Visible at low zoom
- Medium polygons (cities): Visible at medium zoom
- Small polygons (landmarks, buildings): Visible at high zoom

MapLibre handles this automatically based on polygon bounds vs viewport.

### Geographic Region Feedback

When a geographic question is answered:

- **YES**: Region remains, areas outside fade out
- **NO**: Region fades out (semi-transparent → hidden)

Visual feedback of the narrowing search area.

### Auto-Framing

During gameplay, camera automatically adjusts to frame all current candidates:

- Calculate bounding box of remaining candidates
- Zoom and center to fit all in view
- Smooth animation to new framing when candidates change
- Simple algorithm - no special handling for edge cases (distant candidates just zoom out more)

### Home State (`/`)

- Globe slowly rotating
- All known places as uniform short pins
- Tap pin for place name tooltip
- Inviting "explore the world" feel

### Game State (`/game/:sessionId`)

- Auto-rotate stops, user can pan/rotate manually
- Candidate places as 3D pins (height = confidence)
- Auto-frames to show all candidates
- Reframes smoothly when candidates eliminated
- Geographic regions fade when ruled out

### Win/End State

- Camera orbits gently around winning place
- Zoom to show place polygon (if available)
- Success glow/highlight on winning pin

## Animation Guidelines

### Principles

- Purposeful: Communicates state changes
- Quick: 150-300ms typical
- Smooth: Ease-out enters, ease-in exits
- Respectful: Honor prefers-reduced-motion

### Route Transitions

| Transition  | Animation                                             |
| ----------- | ----------------------------------------------------- |
| Home → Game | Panel slides to corner, content crossfades            |
| Game → Home | Panel slides to center, content crossfades            |
| Any → Auth  | Panel moves to center (if needed), content crossfades |
| Any → Stats | Panel moves to center (if needed), content crossfades |

### In-View Animations

| Element           | Animation          |
| ----------------- | ------------------ |
| New chat message  | Fade in + slide up |
| Question change   | Crossfade text     |
| Marker eliminated | Fade + shrink      |
| Confidence change | Marker scale       |
| Correct guess     | Success pulse      |

## Loading States

- Buttons: Spinner replaces text, disabled
- Chat: Typing indicator (dots) for system "thinking"
- Map: Basemap immediate, markers progressive
- Stats: Skeleton placeholders
- Route change: Brief loading state if data fetch needed

## Error Handling

- Game errors: System message in chat (styled distinctly)
- Auth errors: Inline below form fields
- Network errors: Toast notification
- Invalid route/session: Error message in panel with navigation options

## Accessibility

- Full keyboard navigation
- ARIA labels on icon buttons
- Live regions for chat updates
- Focus management on route transitions
- WCAG AA color contrast
- Reduced motion support
- Touch targets minimum 44x44px
