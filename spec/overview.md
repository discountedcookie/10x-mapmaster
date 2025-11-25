# 10x-Mapmaster Specification

## Overview

10x-Mapmaster is an intelligent geography guessing game where players describe places, and the system asks strategic yes/no questions to identify them. The system learns from every session using semantic embeddings and accumulated gameplay knowledge.

## Constraints

- Built-in Supabase tools (auth, RLS, edge functions)
- PostgreSQL extensions (pgvector, PostGIS, pg_cron)
- Free and public resources where possible (Natural Earth, Nominatim)
- Small LLMs for small tasks (trait extraction, question generation)
- Smart algorithms over hardcoded filters

## Glossary

| Term               | Definition                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| **Candidate**      | A place that potentially matches the player's description, scored by similarity                 |
| **Confidence**     | Probability that a candidate is the correct place, derived from similarity scores via softmax   |
| **Embedding**      | 384-dimensional vector representation of text, used for semantic similarity                     |
| **Entropy**        | Measure of how spread out confidence is across candidates (low = concentrated, high = spread)   |
| **Learning**       | Process of extracting new traits from player descriptions and updating place embeddings         |
| **Margin**         | Difference in confidence between top two candidates                                             |
| **Pending review** | Session/place awaiting admin approval before contributing to learning                           |
| **Place**          | A geographic location with traits, embedding, and geometry                                      |
| **Power-law**      | Scaling formula where stronger matches get proportionally more weight (adjustment × strength^β) |
| **RLS**            | Row Level Security - PostgreSQL feature that restricts data access based on user identity       |
| **Softmax**        | Function that converts scores to probabilities summing to 1.0, with temperature control         |
| **Split quality**  | How evenly a question divides candidates (1.0 = perfect 50/50 split)                            |
| **Trait**          | A semantic characteristic of a place (e.g., "tall iron structure", "coastal location")          |
| **Turn**           | One question-answer cycle; all answers (yes/no/not sure) cost one turn                          |

## Architecture Philosophy

**Database-First Design**: All business logic, game mechanics, scoring, and state management lives in PostgreSQL. The frontend is purely presentational.

**Traits-Based Questions**: Instead of storing static questions, the system stores canonical traits and generates contextual questions using LLM integration.

**Semantic Intelligence**: Uses pgvector for semantic similarity between descriptions, traits, and places, combined with PostGIS for geographic filtering.

## Documentation Structure

```
spec/
├── overview.md      # This file - project overview and core principles
├── architecture.md  # Technical architecture and design decisions
├── gameplay.md      # Game flows and user experience
├── algorithm.md     # Mathematical formulas and decision logic
├── ui.md            # UI components, theming, and visual design
└── operations.md    # Deployment and operational design
```

## Quick Reference

### Core Game Functions

- `start_game(description_text)` - Initialize new game session
- `play_turn(session_id, response)` - Process player response

### Key Configuration

All tunable values stored in config tables split by visibility. See `spec/algorithm.md` for full reference.

- `public.config` - Client-visible settings (e.g., `game.max_turns`)
- `game_logic.config` - Server-only settings (scoring, thresholds, LLM prompts)

- `game.*` - Game rules (max_turns)
- `scoring.*` - Candidate scoring (temperature, thresholds)
- `confidence.*` - Guess decision (top_prob, margin, entropy thresholds)
- `traits.*` - Trait matching (match thresholds, power-law weights)
- `questions.*` - Question selection (split quality thresholds)
- `llm.*` - LLM settings (model, temperature, prompts)

### Security Model

- `public` schema: Read-only data (places, traits, `public.config`)
- `game_logic` schema: Private data (LLM prompts, scoring weights in `game_logic.config`)
- RLS policies: Users see only their own game sessions
