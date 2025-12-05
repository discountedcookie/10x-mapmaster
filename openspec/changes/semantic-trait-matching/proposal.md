# Change: Semantic Trait Matching

## Why

The current algorithm uses **binary trait lookup** with boost/penalty factors. This wastes the richness of embeddings and makes NOT_SURE useless. We can do better.

## Goal

Make the game feel smart:

- **Specific descriptions** → guess right away
- **Vague descriptions** → ask smart questions, narrow down quickly
- **Known places** → never fail to find them
- **Answers matter** → scores visibly react to each answer
- **NOT_SURE helps** → narrows possibilities, doesn't stall

## Core Math

### Ordinal Response Model

Answers are YES / NOT_SURE / NO, not binary. Each has a probability:

```
η(i, q) = α_q · (sim(i, q) - m_q)

P(NO | η)       = 1 - σ(η - δ₀)
P(NOT_SURE | η) = σ(η - δ₀) - σ(η - δ₁)
P(YES | η)      = σ(η - δ₁)

where δ₀ < δ₁ are thresholds, σ = sigmoid
```

NOT_SURE is **information** — it locates where a place sits relative to the trait boundary.

### Per-Trait Parameters from Embeddings

Each trait has its own discrimination (α_q) and difficulty (m_q), predicted from its embedding:

```
α_q = w_α · e_q + b_α     (how sharply does this trait separate places?)
m_q = w_m · e_q + b_m     (how high must similarity be for YES?)
```

This means **new traits work automatically** — no need to calibrate each one.

### Learned Similarity Metric

Raw cosine from LLM embeddings is optimized for language, not geography. We can learn a better metric:

```
sim_W(place, trait) = normalized_dot(W·e_place, W·e_trait)
```

Options to explore:

- **Diagonal W** — reweight embedding dimensions
- **Low-rank W** — project to a geography-relevant subspace
- **Raw cosine** — maybe it's fine, we'll see

### Score Updates

For each answer, update all candidate scores:

```sql
log_score[i] += ln(P(answer | place=i, trait=q))
```

All three answers contribute likelihood. NOT_SURE doesn't zero out.

### Question Selection (Three-Outcome Information Gain)

Pick the trait that maximizes expected information:

```
IG(q) = H(now) - Σ_{y ∈ {YES, NOT_SURE, NO}} P(y) · H(after | y)
```

Traits where NOT_SURE is informative get selected.

## What to Explore

### Model Variations

| Model                   | What it does                      | Why try it      |
| ----------------------- | --------------------------------- | --------------- |
| Global ordinal          | Same (α, m) for all traits        | Simple baseline |
| Per-trait ordinal       | Each trait gets (α_q, m_q)        | Might overfit   |
| Embedding-parameterized | Predict (α_q, m_q) from embedding | New traits work |

### Metric Variations

| Metric     | What it does             | Why try it                    |
| ---------- | ------------------------ | ----------------------------- |
| Raw cosine | Current approach         | Baseline                      |
| Whitened   | Fix embedding anisotropy | Cheap improvement?            |
| Diagonal W | Reweight dimensions      | Which dimensions matter?      |
| Low-rank W | Project to subspace      | Find geography-relevant space |

### Interesting Questions

- Do some traits discriminate sharply, others fuzzily?
- Which embedding dimensions carry geographic signal?
- Does game phase matter? (early questions vs late confirmation)

## Tooling

This change includes infrastructure for testing and tuning:

### Algorithm Tuning Skill (`.opencode/skills/algorithm-tuning/`)

Skill for agents to inspect and tune the algorithm:

```markdown
# What agents can do with this skill:

## Inspect current game state

- View candidates with scores, probabilities, similarities
- See which traits are being considered for next question
- Understand why a particular candidate is ranked high/low

## Understand score changes

- See how each answer affected candidate rankings
- Identify which answers had biggest impact
- Trace why a place got eliminated or promoted

## Tune parameters

- Adjust ordinal thresholds (δ₀, δ₁)
- Modify trait parameter weights (w_α, w_m)
- Switch between similarity metrics

## Run test scenarios

- Play through specific descriptions
- Compare score trajectories
- Find failure cases
```

### SQL Views for Inspection

| View               | Purpose                                      |
| ------------------ | -------------------------------------------- |
| `algorithm_state`  | Current candidates with scores, similarities |
| `trait_evaluation` | Traits with (α_q, m_q) and information gain  |
| `turn_impact`      | How each answer changed rankings             |

### Game Logging & Replay

```sql
-- Log table stores per-turn snapshots
game_logic.game_log (
  session_id,
  turn,
  candidates_json,
  question,
  answer
)
-- Replay function returns turn-by-turn progression
SELECT
  *
FROM
  replay_game ('session-uuid');
```

### Batch Testing Script

```bash
# Run games against known places
bun run scripts/batch-test-games.ts --input test-cases.json

# Output: turns_to_guess, correct?, score_progression
# Summary: success rate, avg turns, failure cases
```

### OpenCode Tools (Future)

Potential custom tools for even smoother workflow:

| Tool                 | Purpose                                           |
| -------------------- | ------------------------------------------------- |
| `inspect-candidates` | Show current algorithm state for a session        |
| `explain-score`      | Why does this place have this score?              |
| `test-description`   | Run a game with given description, report results |
| `compare-configs`    | Run same game with different parameters           |

## Phases

### 1. Build Core

- Ordinal probability functions
- Embedding-parameterized (α_q, m_q)
- Three-outcome score updates
- Three-outcome information gain

### 2. Add Tooling

- Algorithm inspection views
- Game replay capability
- Batch testing scripts

### 3. Explore Variations

- Try different model/metric combinations
- See what actually helps
- Keep what works, drop what doesn't

### 4. Tune

- Play games, observe behavior
- Adjust parameters
- Iterate until it feels right

## What Doesn't Change

- Geographic filtering (PostGIS)
- LLM question text generation
- Session flow and UI

## Configuration

| Key                              | Type   | Description                        |
| -------------------------------- | ------ | ---------------------------------- |
| `model.w_alpha`                  | vector | Embedding → discrimination weights |
| `model.w_m`                      | vector | Embedding → difficulty weights     |
| `model.b_alpha`, `model.b_m`     | scalar | Intercepts                         |
| `model.delta_0`, `model.delta_1` | scalar | Ordinal thresholds                 |
| `metric.type`                    | string | 'cosine' / 'diagonal' / 'low_rank' |
| `metric.W`                       | matrix | Learned transformation (if used)   |

Parameters are tuned through testing, not hand-picked.
