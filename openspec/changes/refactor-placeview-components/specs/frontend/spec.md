## MODIFIED Requirements

### Requirement: Component Size Limit

View components SHALL stay under 200 lines by extracting reusable components.

#### Scenario: PlaceView structure

- **WHEN** PlaceView is rendered
- **THEN** the view component is under 200 lines
- **AND** shared UI is extracted to child components
- **AND** responsive behavior uses CSS or minimal template duplication

### Requirement: DRY Templates

The system SHALL NOT duplicate template code for responsive layouts when the content is identical.

#### Scenario: Mobile and desktop layouts

- **WHEN** the same content is shown on mobile and desktop
- **THEN** a single component renders the content
- **AND** CSS handles layout differences
- **OR** the component accepts layout props
