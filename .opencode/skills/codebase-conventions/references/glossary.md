# Domain Glossary

Quick reference for 10x-Mapmaster domain terms. Full definitions in `docs/overview.md`.

## Game Concepts

| Term | Definition | Where It Lives |
|------|------------|----------------|
| **Candidate** | Place potentially matching description | `game_logic.get_candidates()` |
| **Confidence** | Probability a candidate is correct (softmax) | `game_logic.calculate_confidence()` |
| **Margin** | Difference between top two candidates | Part of confidence metrics |
| **Entropy** | How spread out confidence is | Part of confidence metrics |
| **Turn** | One question-answer cycle | `game_sessions.turn_number` |
| **Trait** | Semantic characteristic of a place | `place_traits` table |
| **Split quality** | How evenly a question divides candidates | `game_logic.calculate_split_quality()` |

## Technical Terms

| Term | Definition | Example |
|------|------------|---------|
| **Embedding** | 384-dimensional vector for semantic similarity | `embeddings.embedding` |
| **RLS** | Row Level Security - restricts data by user | `auth.uid() = user_id` |
| **SECURITY DEFINER** | Function runs with owner privileges | `start_game`, `play_turn` |
| **Softmax** | Converts scores to probabilities summing to 1.0 | Temperature parameter controls spread |
| **Power-law** | Stronger matches get proportionally more weight | `adjustment × strength^β` |

## Config Keys

| Key Pattern | Purpose | Location |
|-------------|---------|----------|
| `game.*` | Game rules (max_turns) | `public.config` |
| `scoring.*` | Candidate scoring | `game_logic.config` |
| `confidence.*` | Guess decision thresholds | `game_logic.config` |
| `traits.*` | Trait matching parameters | `game_logic.config` |
| `questions.*` | Question selection | `game_logic.config` |
| `llm.*` | LLM settings and prompts | `game_logic.config` |

## Status Values

### Game Session
- `active` - Game in progress
- `won` - System guessed correctly
- `ended` - Max turns, no win
- `needs_submission` - Awaiting correct place

### Answer
- `yes` - Affirmative (questions and guesses)
- `no` - Negative (questions and guesses)
- `not_sure` - Uncertain (questions ONLY)
