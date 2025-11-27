## ADDED Requirements

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
