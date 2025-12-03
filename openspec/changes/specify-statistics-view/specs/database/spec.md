## MODIFIED Requirements

### Requirement: Stats Views

The system SHALL provide user and global statistics via read-only views with proper access controls.

#### Scenario: User stats

- **WHEN** a user queries the user-facing stats view (e.g., game_session_stats)
- **THEN** they see only their row with games played, games won, win rate, average turns to win, places added, and last played timestamp.

#### Scenario: Global stats

- **WHEN** a user queries the global stats view
- **THEN** they see aggregated columns such as total games, games in the last 24 hours, total users, total places, total traits, and overall win rate and average turns to win.
