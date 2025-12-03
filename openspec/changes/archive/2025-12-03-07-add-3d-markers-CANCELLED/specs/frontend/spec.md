## MODIFIED Requirements

### Requirement: Map Visualization

The system SHALL visualize candidates and regions on the globe with appropriate feedback and camera controls.

#### Scenario: Candidate visualization

- **WHEN** candidates exist
- **THEN** they render as deck.gl PolygonLayer with extrusion height based on confidence

#### Scenario: Geographic feedback

- **WHEN** geographic answers are given
- **THEN** regions are highlighted/cleared accordingly

#### Scenario: Camera behavior

- **WHEN** a guess or focal candidate is chosen
- **THEN** the camera frames the relevant geometry

#### Scenario: 3D marker states

- **WHEN** candidate confidence changes
- **THEN** extrusion height animates smoothly; top candidate is tallest with glow; eliminated candidates shrink
