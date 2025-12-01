## MODIFIED Requirements

### Requirement: Map Visualization

The system SHALL visualize candidates and regions on the globe with appropriate feedback and camera controls.

#### Scenario: Candidate visualization

- **WHEN** candidates exist
- **THEN** they render as deck.gl layers with confidence-aware styling

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
