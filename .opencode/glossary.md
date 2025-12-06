# Agent Glossary

Quick lookup for 10x-Mapmaster domain terms. Load when you need fast definitions.

## Core Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `places` | Known geographic places | `id`, `name`, `osm_id`, `lat`, `lng` |
| `traits` | Semantic characteristics | `id`, `clause`, `embedding_id` |
| `place_traits` | Many-to-many link | `place_id`, `trait_id` |
| `embeddings` | Vector storage | `id`, `embedding`, `source_text` |
| `game_sessions` | Active games | `id`, `user_id`, `description`, `status` |
| `game_answers` | Question responses | `session_id`, `trait_id`, `answer` |
| `geographic_regions` | PostGIS regions | `id`, `name`, `geometry` |

## Game States

| Status | Meaning |
|--------|---------|
| `active` | Game in progress, awaiting answer |
| `won` | System guessed correctly |
| `ended` | Max turns reached |
| `needs_submission` | Awaiting correct place from player |

## Answer Values

| Answer | Valid For | Effect |
|--------|-----------|--------|
| `yes` | Questions + Guesses | Boost matching candidates |
| `no` | Questions + Guesses | Penalize matching candidates |
| `not_sure` | Questions ONLY | No score adjustment |

## Scoring Concepts

| Term | Formula/Config |
|------|----------------|
| **Softmax** | `P(i) = exp(score/T) / sum(exp(scores/T))` |
| **Temperature** | `scoring.temperature` - lower = sharper distribution |
| **Margin** | `P(top) - P(second)` |
| **Entropy** | `-sum(P * ln(P))` - lower = more confident |
| **Split quality** | `1 - abs(0.5 - fraction_matching)` |

## Config Prefixes

| Prefix | Table | Examples |
|--------|-------|----------|
| `game.*` | `public.config` | `game.max_turns` |
| `scoring.*` | `game_logic.config` | `scoring.temperature` |
| `confidence.*` | `game_logic.config` | `confidence.top_prob_threshold` |
| `traits.*` | `game_logic.config` | `traits.boost_factor` |
| `questions.*` | `game_logic.config` | `questions.min_split_quality` |
| `llm.*` | `game_logic.config` | `llm.trait_extraction.model` |

## Key Functions

| Function | Purpose | Schema |
|----------|---------|--------|
| `start_game(description)` | Begin new session | `public` |
| `play_turn(session_id, answer)` | Submit answer | `public` |
| `submit_correct_place(session_id, osm_id)` | End with correct place | `public` |
| `get_candidates(session_id)` | Current candidates | `game_logic` |
| `calculate_confidence(session_id)` | Confidence metrics | `game_logic` |
| `update_place_traits(place_id)` | Refresh traits from LLM | `game_logic` |
| `get_embedding(text, input_type)` | Generate/retrieve embedding | `game_logic` |

## Embedding Types

| Input Type | Use Case |
|------------|----------|
| `query` | User searches (descriptions) |
| `passage` | Stored content (traits) |

## Vector Operators

| Operator | Meaning | Use Case |
|----------|---------|----------|
| `<=>` | Cosine distance | Semantic similarity (use this) |
| `<->` | L2/Euclidean | Rare |
| `<#>` | Inner product | Rare |

## PostGIS Functions

| Function | Purpose |
|----------|---------|
| `ST_Contains(region, point)` | Is point inside region? |
| `ST_Distance(a, b)` | Distance between geometries |
| `ST_MakePoint(lng, lat)` | Create point geometry |
| `ST_SetSRID(geom, 4326)` | Set WGS84 coordinate system |

## File Locations

| Category | Path |
|----------|------|
| DB functions | `supabase/db/game_logic/functions/` |
| DB schema | `supabase/db/schema/` |
| DB views | `supabase/db/public/views/` |
| Edge functions | `supabase/functions/` |
| Vue components | `src/components/` |
| Composables | `src/composables/` |
| Stores | `src/stores/` |
| Specs | `openspec/specs/` |
| Skills | `.opencode/skills/` |

## Common Patterns

### RPC Call from Frontend
```typescript
const { data, error } = await supabase.rpc('function_name', { param: value })
```

### Get Config Value
```sql
game_logic.get_config('key')           -- JSONB
game_logic.get_config_text('key')      -- TEXT
game_logic.get_config_int('key')       -- INTEGER
game_logic.get_config_float('key')     -- FLOAT
```

### Similarity Search
```sql
1 - (embedding <=> query_embedding) AS similarity
```

### Geographic Check
```sql
ST_Contains(region.geometry, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
```
