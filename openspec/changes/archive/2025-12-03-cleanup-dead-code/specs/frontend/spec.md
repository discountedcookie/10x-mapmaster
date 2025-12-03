## REMOVED Requirements

### Requirement: Apply Answer to Session State (REMOVED)

This function was a no-op placeholder. Session state updates are handled directly in `play_turn()`.

## MODIFIED Requirements

### Requirement: View Component Props

View components SHALL only define props that are actually used.

#### Scenario: Auth view rendering

- **WHEN** LoginView or SignupView is rendered
- **THEN** no unused props are defined
- **AND** the component functions correctly without renderMode
