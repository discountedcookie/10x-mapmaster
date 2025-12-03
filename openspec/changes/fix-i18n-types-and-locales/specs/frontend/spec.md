## MODIFIED Requirements

### Requirement: Stats and Settings UI

The system SHALL present stats views and user settings without embedding game logic.

#### Scenario: Stats views

- **WHEN** users open stats
- **THEN** user_stats/global_stats are displayed using data from database views

#### Scenario: Theme and language

- **WHEN** toggling theme or language
- **THEN** the UI updates accordingly and preferences are respected using locales `en`, `es`, and `pl`

#### Scenario: Accessibility

- **WHEN** interacting with settings and stats
- **THEN** controls are accessible (keyboard/ARIA/reduced motion)

### Requirement: Localization Configuration

The system SHALL configure vue-i18n so that message typing is consistent with the shared message schema and uses short locale codes.

#### Scenario: Locale identifiers

- **WHEN** the frontend selects or displays a locale
- **THEN** it uses short codes `en`, `es`, `pl` and maps browser locales like `en-US` to `en`.

#### Scenario: Type-safe messages

- **WHEN** compiling the frontend
- **THEN** vue-i18n types align with the message schema and the build passes without i18n-related type errors.
