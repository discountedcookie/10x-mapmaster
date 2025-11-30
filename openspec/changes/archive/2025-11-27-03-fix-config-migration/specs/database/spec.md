## ADDED Requirements

### Requirement: Server-Only Algorithm Configuration

The system SHALL store algorithm configuration in a server-only schema inaccessible to clients.

#### Scenario: Config table isolation

- **WHEN** algorithm parameters are stored
- **THEN** they reside in `game_logic.config` with RLS blocking client access

#### Scenario: Hierarchical key naming

- **WHEN** config values are accessed
- **THEN** keys use dot-notation hierarchy (e.g., `confidence.top_prob_threshold`)

#### Scenario: Consistent access pattern

- **WHEN** game logic functions read configuration
- **THEN** they use `game_logic.get_config(key)` helper function
