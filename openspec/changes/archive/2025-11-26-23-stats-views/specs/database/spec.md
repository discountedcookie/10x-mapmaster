## ADDED Requirements

### Requirement: Stats Views

The system SHALL provide user and global statistics via read-only views with proper access controls.

#### Scenario: User stats

- **WHEN** a user queries user_stats
- **THEN** they see only their row with games_played, games_won, win_rate, avg_turns_to_win, places_added, last_played_at

#### Scenario: Global stats

- **WHEN** a user queries global_stats
- **THEN** they see aggregated columns (total_games, games_last_24h, total_users, total_places, total_traits, overall_win_rate, avg_turns_to_win) if authenticated
