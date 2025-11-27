## MODIFIED Requirements

### Requirement: Map Visualization

The system SHALL visualize candidates and regions on the globe with appropriate feedback and camera controls.

#### Scenario: Candidate visualization

- **WHEN** candidates exist
- **THEN** they render as deck.gl layers with confidence-aware styling

#### Scenario: Geographic feedback

- **WHEN** geographic answers are given
- **THEN** YES keeps region visible (areas outside fade), NO fades region out with opacity transition

#### Scenario: Camera behavior

- **WHEN** a guess or focal candidate is chosen
- **THEN** the camera frames the relevant geometry

#### Scenario: Region state tracking

- **WHEN** the game progresses
- **THEN** active and eliminated regions are tracked and visually distinguished
