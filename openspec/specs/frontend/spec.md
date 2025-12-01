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
- **THEN** they render as deck.gl layers with confidence-aware styling

#### Scenario: Geographic feedback

- **WHEN** geographic answers are given
- **THEN** regions are highlighted/cleared accordingly

#### Scenario: Camera behavior

- **WHEN** a guess or focal candidate is chosen
- **THEN** the camera frames the relevant geometry

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
