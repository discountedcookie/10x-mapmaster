## ADDED Requirements

### Requirement: Map Composable Testability

The system SHALL provide map-related composables that can be validated via unit tests using mocked map implementations.

#### Scenario: Map camera composables

- **WHEN** running unit tests for `useMapCamera`, `useMapCenterTracking`, and `useZoomPitchCorrelation`
- **THEN** camera state, tracking, and zoom/pitch relationships can be asserted without requiring real MapLibre or deck.gl rendering.

#### Scenario: Auto-rotation and intro composables

- **WHEN** running unit tests for `useAutoRotation`, `useGlobeVisibility`, and `useCinematicIntro`
- **THEN** starting, stopping, pausing, and skipping behaviors can be exercised with mocked map events.

#### Scenario: Place presentation composables

- **WHEN** running unit tests for `usePlacePresentation`
- **THEN** conversion from places to marker/candidate structures follows the specified mapping behavior and is testable without real map instances.
