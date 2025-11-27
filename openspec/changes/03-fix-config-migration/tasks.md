## 1. Schema Updates

- [x] 1.1 Create `game_logic.config` table if not exists (key TEXT PRIMARY KEY, value JSONB) - already exists
- [x] 1.2 Add RLS to block client access to `game_logic.config` - already configured

## 2. Seed Data Migration

- [x] 2.1 Move algorithm params from `app_settings` to `game_logic.config` with hierarchical keys:
  - `confidence.top_prob_threshold`
  - `confidence.margin_threshold`
  - `confidence.entropy_threshold`
  - `scoring.temperature`
  - `traits.similarity_threshold`
  - `questions.min_split_quality`
  - `questions.geographic_preference_threshold`

## 3. Function Updates

- [x] 3.1 Update `decide_next_turn.sql` to read from `game_logic.config`
- [x] 3.2 Update `handle_question.sql` to read from `game_logic.config`
- [ ] 3.3 Update `get_initial_candidates.sql` to read from `game_logic.config` - not needed, uses defaults
- [x] 3.4 Update `select_best_question.sql` to read from `game_logic.config`
- [x] 3.5 Create helper `get_config(key)` function for consistent access

## 4. Testing

- [ ] 4.1 Add pgTAP test for config access from game_logic functions
- [ ] 4.2 Test that `public` schema cannot read `game_logic.config`
- [ ] 4.3 Verify game works with migrated config
