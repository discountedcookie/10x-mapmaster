# Frontend Specification

## Purpose

Define the Vue 3 frontend presentation layer, including UI components, map visualization, chat interface, and user interactions. Frontend is presentation only - no business logic.

---

## Requirements

### Requirement: Single Map Instance

The system SHALL render the map once and never remount it.

#### Scenario: Map persistence

- **WHEN** route changes
- **THEN** map instance persists
- **AND** only markers, center, zoom, and highlights update

#### Scenario: Seamless transitions

- **WHEN** navigating between routes
- **THEN** map transitions smoothly without reload

---

### Requirement: Globe Projection

The system SHALL use MapLibre globe projection throughout.

#### Scenario: Globe view

- **WHEN** map renders
- **THEN** uses globe projection (not flat map)

#### Scenario: Home state rotation

- **WHEN** on home route with no active game
- **THEN** globe slowly auto-rotates

#### Scenario: Game state

- **WHEN** game active
- **THEN** auto-rotate stops, user can pan/rotate

---

### Requirement: Layout Structure

The system SHALL use floating panel over persistent map.

#### Scenario: Layout components

- **WHEN** app renders
- **THEN** map fills viewport
- **AND** nav elements float (logo top-left, avatar menu top-right)
- **AND** RouterView renders in floating panel

#### Scenario: Panel positioning

- **WHEN** on home/login/signup/stats routes
- **THEN** panel centered, medium width
- **WHEN** on game route
- **THEN** panel in corner (bottom-right desktop, bottom mobile)

---

### Requirement: Route Structure

The system SHALL support defined routes with appropriate panel content.

#### Scenario: Home route (/)

- **WHEN** user visits home
- **THEN** panel shows description input, submit button
- **AND** map shows all known places

#### Scenario: Game route (/game/:sessionId)

- **WHEN** user visits game
- **THEN** panel shows chat conversation
- **AND** map shows candidates with 3D markers

#### Scenario: Auth routes (/login, /signup)

- **WHEN** user visits auth routes
- **THEN** panel shows appropriate form
- **AND** redirects if already authenticated

#### Scenario: Stats route (/stats)

- **WHEN** registered user visits stats
- **THEN** panel shows user statistics from user_stats view
- **AND** anonymous users redirected to login

#### Scenario: Global stats route (/stats/global)

- **WHEN** user visits global stats
- **THEN** panel shows global metrics from global_stats view

---

### Requirement: Theme System

The system SHALL support light, dark, and system themes.

#### Scenario: Theme toggle

- **WHEN** user toggles theme
- **THEN** cycles Light → Dark → System → Light

#### Scenario: Map basemap switching

- **WHEN** theme changes
- **THEN** map switches basemap (Positron for light, Dark Matter for dark)

#### Scenario: Theme persistence

- **WHEN** theme selected
- **THEN** stored in localStorage only (not database)

---

### Requirement: Chat Interface

The system SHALL display game interaction as chat conversation.

#### Scenario: User messages

- **WHEN** user submits input
- **THEN** displayed right-aligned with primary color

#### Scenario: System messages

- **WHEN** system asks question or makes guess
- **THEN** displayed left-aligned with muted color

#### Scenario: Error messages

- **WHEN** error occurs
- **THEN** displayed as system message with distinct styling

---

### Requirement: Contextual Input Area

The system SHALL show appropriate input based on game state.

#### Scenario: Question state

- **WHEN** system asks question
- **THEN** show Yes / No / Not Sure buttons

#### Scenario: Guess state

- **WHEN** system makes guess
- **THEN** show Yes / No buttons

#### Scenario: Give up state

- **WHEN** game needs place submission
- **THEN** show place search with Nominatim autocomplete

#### Scenario: Won/ended state

- **WHEN** game complete
- **THEN** show Play Again button

---

### Requirement: 3D Extruded Markers

The system SHALL visualize candidates as 3D extruded polygons via deck.gl.

#### Scenario: Polygon source

- **WHEN** place has geometry
- **THEN** use actual polygon from Nominatim
- **WHEN** place lacks geometry
- **THEN** generate circle polygon from point coordinates

#### Scenario: Height by confidence

- **WHEN** rendering candidates
- **THEN** extrusion height represents confidence
- **AND** top candidate is tallest

#### Scenario: Visual states

- **WHEN** top candidate
- **THEN** primary color with glow, pulse animation
- **WHEN** other candidates
- **THEN** muted color, subtle breathing animation
- **WHEN** eliminated
- **THEN** shrinks and fades out

---

### Requirement: Candidate List Display

The system SHALL show candidate list in chat panel.

#### Scenario: List content

- **WHEN** game active
- **THEN** shows ranked candidates with name and confidence bar

#### Scenario: Click interaction

- **WHEN** user clicks candidate
- **THEN** map pans/zooms to that location

---

### Requirement: Auto-Framing

The system SHALL automatically frame candidates in view.

#### Scenario: Frame candidates

- **WHEN** candidates change
- **THEN** calculate bounding box
- **AND** smoothly animate camera to fit all candidates

---

### Requirement: Navigation Menu

The system SHALL provide avatar menu for settings and actions.

#### Scenario: Anonymous user menu

- **WHEN** anonymous user opens menu
- **THEN** shows Theme, Language, Sign in options

#### Scenario: Registered user menu

- **WHEN** registered user opens menu
- **THEN** shows Theme, Language, Stats, Sign out options

#### Scenario: Language selection

- **WHEN** user selects language
- **THEN** stored in localStorage
- **AND** affects LLM-generated questions

---

### Requirement: Loading States

The system SHALL show appropriate loading feedback.

#### Scenario: Button loading

- **WHEN** async operation in progress
- **THEN** button shows spinner, disabled

#### Scenario: Chat loading

- **WHEN** waiting for system response
- **THEN** show typing indicator (dots)

---

### Requirement: Error Handling

The system SHALL handle errors gracefully without automatic recovery.

#### Scenario: Error display

- **WHEN** error occurs
- **THEN** parse error_code from response
- **AND** display translated message
- **AND** keep UI in current state

#### Scenario: Manual retry

- **WHEN** error displayed
- **THEN** user can retry manually
- **AND** no automatic retries

---

### Requirement: State Management

The system SHALL use Pinia for reactive state.

#### Scenario: Store domains

- **WHEN** managing state
- **THEN** organize by domain: Auth, Game, Places, UI

#### Scenario: Data refresh

- **WHEN** RPC call succeeds
- **THEN** refetch game_sessions row
- **AND** reactive UI updates from table data

---

### Requirement: Accessibility

The system SHALL meet accessibility standards.

#### Scenario: Keyboard navigation

- **WHEN** user uses keyboard
- **THEN** full navigation supported

#### Scenario: Screen readers

- **WHEN** screen reader used
- **THEN** ARIA labels on icon buttons
- **AND** live regions for chat updates

#### Scenario: Reduced motion

- **WHEN** user prefers reduced motion
- **THEN** animations respect preference

#### Scenario: Touch targets

- **WHEN** on mobile
- **THEN** touch targets minimum 44x44px

---

### Requirement: Internationalization

The system SHALL support multiple languages.

#### Scenario: Supported languages

- **WHEN** user selects language
- **THEN** supports English (en) and Polish (pl) in v1

#### Scenario: Translation management

- **WHEN** translations needed
- **THEN** managed via Tolgee

#### Scenario: Browser detection

- **WHEN** first visit
- **THEN** detect language from browser
