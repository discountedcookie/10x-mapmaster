# frontend Specification

## Purpose

Specifies the Vue 3 frontend shell, routing, map visualization, and UI components. The frontend is presentation-only - it displays data from database views and calls RPC functions, never implementing game logic.
## Requirements
### Requirement: Frontend Shell and Routing

The system SHALL provide a layout and routes for the application shell without embedding game logic.

#### Scenario: Layout

- **WHEN** the app loads
- **THEN** MapLayout renders a globe canvas (using MapLibre globe projection) with a floating panel container

#### Scenario: Routing

- **WHEN** navigating
- **THEN** routes /, /game/:id, /login, /signup, /stats, /stats/global are available with navigation controls

#### Scenario: Presentation-only shell

- **WHEN** rendering the shell
- **THEN** it remains presentation-only and defers all game logic to RPC calls

#### Scenario: Globe projection

- **WHEN** the map initializes
- **THEN** it uses globe projection (not flat 2D) with atmospheric styling

### Requirement: Home and Auth Experience

The system SHALL present onboarding and authentication flows and allow starting a game from the home panel.

#### Scenario: Home input

- **WHEN** the home view is shown
- **THEN** users can enter a description and start a game via start_game RPC

#### Scenario: Authentication

- **WHEN** users log in or sign up
- **THEN** Supabase auth handles anonymous, login, and signup flows with appropriate UI feedback

#### Scenario: Accessibility and presentation-only

- **WHEN** interacting with the home/auth UI
- **THEN** controls are accessible and contain no embedded game logic

### Requirement: Gameplay UI

The system SHALL present gameplay UI elements driven by backend next_turn data without embedding game logic.

#### Scenario: Chat and input

- **WHEN** a turn is active
- **THEN** chat history of prior turns is visible and contextual input allows answering, guessing, or giving up per next_turn action

#### Scenario: Candidates and map hooks

- **WHEN** candidates are present
- **THEN** they are listed with confidence bars and can drive map panning/highlights

#### Scenario: Status indicators

- **WHEN** session status/turns change
- **THEN** badges reflect active/won/needs_submission/ended and turn counts

### Requirement: Map Visualization

The system SHALL visualize candidates and regions on the globe with appropriate feedback and camera controls.

#### Scenario: Candidate visualization

- **WHEN** candidates exist
- **THEN** they render as MapLibre native layers (GeoJSON source with circle/fill layers) with confidence-aware styling

#### Scenario: Geographic feedback

- **WHEN** geographic answers are given
- **THEN** regions are highlighted/cleared accordingly

#### Scenario: Idle mode camera (Home)

- **WHEN** on home view with fresh page load
- **THEN** cinematic intro animation plays (spinning globe flydown to first place)
- **AND** after intro, camera drifts between places with smooth fly-to animations

#### Scenario: Idle mode user interaction

- **WHEN** user interacts with map during idle mode (click, drag, wheel)
- **THEN** current animation stops immediately
- **AND** after `pauseBetween` duration of no interaction (from `useAutoRotation`), place rotation resumes from current map position

#### Scenario: Place presentation mode

- **WHEN** viewing a specific place (PlaceView) or presenting a winner (GameView win/submission)
- **THEN** camera flies to place with 55° pitch and starts orbital rotation around the place center
- **AND** place geometry is highlighted with 3D extrusion or marker as appropriate

#### Scenario: Place presentation zoom-pitch correlation

- **WHEN** user zooms in/out during place presentation
- **THEN** pitch interpolates smoothly: 0° at globe view (zoom ≤2), 55° at close view (zoom ≥12)
- **AND** intermediate zoom levels use linear interpolation between these values

#### Scenario: Place presentation interaction restrictions

- **WHEN** in GameView win/submission presentation
- **THEN** user can zoom in/out but cannot pan or stop the orbital rotation

#### Scenario: Place presentation pan-away behavior

- **WHEN** in PlaceView and user starts panning the map
- **THEN** orbital rotation stops immediately
- **AND** pitch smoothly transitions to 0° and bearing to north (0°) over 500ms during the drag
- **AND** on release, after 1.5s delay, if place center is no longer visible, URL redirects to home view while preserving map position

#### Scenario: Candidates mode camera (Game active)

- **WHEN** game is active with candidates available
- **THEN** camera fits all candidates on screen with appropriate padding
- **AND** standard map controls (pan, zoom, rotate) are available

### Requirement: Stats and Settings UI

The system SHALL present stats views and user settings without embedding game logic.

#### Scenario: Stats views

- **WHEN** users open stats
- **THEN** user_stats/global_stats are displayed using data from database views

#### Scenario: Theme and language

- **WHEN** toggling theme or language
- **THEN** the UI updates accordingly and preferences are respected

#### Scenario: Accessibility

- **WHEN** interacting with settings and stats
- **THEN** controls are accessible (keyboard/ARIA/reduced motion)

### Requirement: Localization Configuration

The system SHALL configure vue-i18n with ICU MessageFormat and consistent locale codes.

#### Scenario: Locale identifiers

- **WHEN** the frontend selects or displays a locale
- **THEN** it uses short codes `en`, `es`, `pl` and maps browser locales like `en-US` to `en`

#### Scenario: ICU MessageFormat

- **WHEN** rendering translated text
- **THEN** vue-i18n uses a custom message compiler with `intl-messageformat` for ICU pluralization and select statements

#### Scenario: Type-safe messages

- **WHEN** compiling the frontend
- **THEN** vue-i18n types align with the message schema and the build passes without i18n-related type errors

### Requirement: Map Auto-Rotation

The system SHALL auto-rotate the globe on the home page when idle.

#### Scenario: Idle rotation

- **WHEN** on home page with no active game
- **THEN** the globe slowly auto-rotates showing full globe view

#### Scenario: Interaction pause

- **WHEN** user interacts with the map (pan/zoom)
- **THEN** rotation pauses and resumes after idle timeout

#### Scenario: Game transition

- **WHEN** a game starts
- **THEN** rotation stops and camera transitions to game view

### Requirement: Unit Test Coverage and Stability

The system SHALL provide unit tests for core frontend behavior that remain aligned with the specified UI and store behavior.

#### Scenario: Gameplay UI tests

- **WHEN** running unit tests for the gameplay UI and related stores
- **THEN** tests reflect the specified behavior (e.g., correct store imports, expected labels/text, map integration points) and pass when the implementation conforms to the spec.

#### Scenario: i18n tests

- **WHEN** running i18n unit tests
- **THEN** expectations match the localized strings and locale codes defined by the frontend specification.

#### Scenario: Map integration tests

- **WHEN** running tests that depend on map components
- **THEN** they use stable mocks for map libraries so that tests verify frontend behavior without depending on external rendering details.

### Requirement: Store Error Nullability Convention

The system SHALL use a consistent nullability convention for error state in frontend stores and composables.

#### Scenario: Error state type

- **WHEN** defining error refs in stores or composables
- **THEN** they use null as the "no error" value (e.g., Ref<string | null>) rather than undefined.

#### Scenario: Error reset behavior

- **WHEN** a previously errored operation later succeeds
- **THEN** the corresponding error state is reset to null.

#### Scenario: Test expectations

- **WHEN** running unit tests for stores and composables with error state
- **THEN** tests expect null for empty error state and match the standardized nullability convention.

### Requirement: Store Mutation Pattern

The system SHALL mutate Pinia store state only through defined actions.

#### Scenario: Adding a place via realtime

- **WHEN** a realtime INSERT event is received
- **THEN** the `addPlace` action is called
- **AND** Vue devtools records the action

#### Scenario: Updating a place via realtime

- **WHEN** a realtime UPDATE event is received
- **THEN** the `updatePlace` action is called
- **AND** Vue devtools records the action

#### Scenario: Removing a place via realtime

- **WHEN** a realtime DELETE event is received
- **THEN** the `removePlace` action is called
- **AND** Vue devtools records the action

### Requirement: Cross-Store Dependencies

The system SHALL inject cross-store dependencies at store setup time, not inside computeds.

#### Scenario: Store accessing another store

- **WHEN** a store needs data from another store
- **THEN** the dependency is established at setup time
- **AND** computeds reference the injected store instance

