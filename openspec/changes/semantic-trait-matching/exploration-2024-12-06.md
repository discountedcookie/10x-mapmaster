# Exploration: Rethinking Traits, Tags, and Embeddings

**Date:** December 6, 2024  
**Status:** Exploration complete, ready for design decisions  
**Context:** Late-night deep dive into the fundamental architecture of semantic matching

---

## 1. What We Landed On

### The Tag-Embedding Hybrid Architecture

After exploring multiple approaches, we converged on a hybrid model that separates concerns cleanly:

```
┌─────────────────────────────────────────────────────────────┐
│                         TAGS                                │
│                                                             │
│  Fixed vocabulary of question concepts:                     │
│  "coastal", "historic", "capital", "mountainous", etc.      │
│                                                             │
│  Each tag has:                                              │
│    - A name (human-readable)                                │
│    - An embedding (learned vector)                          │
│    - Question templates (for LLM translation)               │
│                                                             │
│  Used for:                                                  │
│    - Question SELECTION (which tag to ask about?)           │
│    - Question GENERATION (tag → natural language)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PLACE EMBEDDINGS                         │
│                                                             │
│  ONE rich embedding per place that captures everything:     │
│    - Geographic properties                                  │
│    - Cultural significance                                  │
│    - Historical context                                     │
│    - All the nuance from descriptions                       │
│                                                             │
│  Generated from:                                            │
│    - Nominatim data                                         │
│    - User descriptions (crowdsourced over time)             │
│    - LLM-curated consolidated knowledge                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SCORING MECHANISM                        │
│                                                             │
│  similarity = cosine(place_embedding, tag_embedding)        │
│  probability = sigmoid(α * (similarity - threshold))        │
│  score_update = log(probability)                            │
│                                                             │
│  When user answers YES to "Is it coastal?":                 │
│    - Very coastal places: big positive update               │
│    - Somewhat coastal: small positive update                │
│    - Inland with lakes: tiny positive update                │
│    - Desert: negative update                                │
│                                                             │
│  Nothing gets killed outright. Gradual belief shifts.       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  VISIBLE PROBABILITIES                      │
│                                                             │
│  probabilities = softmax(scores)                            │
│                                                             │
│  User sees candidates rise and fall naturally.              │
│  The game visibly "thinks" — not binary filtering.          │
│  This is the magic that makes it feel intelligent.          │
└─────────────────────────────────────────────────────────────┘
```

### Key Insight: Separation of Concerns

| Concern       | Handled By              | Why                                    |
| ------------- | ----------------------- | -------------------------------------- |
| What to ask   | Tags (structured)       | Need discrete vocabulary for questions |
| How to score  | Embeddings (continuous) | Need gradual similarity, not binary    |
| How to phrase | LLM (natural language)  | Need human-friendly questions          |

### Comparison to Original Proposal

| Aspect           | Original (per-trait embeddings)      | New (tag embeddings)                     |
| ---------------- | ------------------------------------ | ---------------------------------------- |
| Structure        | Many traits per place, each embedded | Tags as vocabulary, places embedded once |
| Complexity       | High (trait aggregation, soft top-k) | Medium (simpler joins)                   |
| Question source  | Traits ARE questions                 | Tags ARE questions                       |
| Scoring          | Trait similarity weighted            | Tag-place similarity                     |
| Flexibility      | Very flexible                        | Structured but sufficient                |
| Interpretability | Traits are semantic                  | Tags are categorical                     |

### The LLM's Role is Limited

This was an explicit design goal. LLMs are used for exactly two things:

1. **Trait curation**: Consolidating knowledge from Nominatim, user descriptions, and other sources into solid place embeddings and tag assignments.

2. **Question translation**: Converting the algorithm's chosen tag into natural-sounding questions in the user's language.

Everything else is **algorithmic**:

- Which tag to ask about → information gain calculation
- How to score candidates → embedding similarity math
- When to guess → probability thresholds

---

## 2. What We Thought About and Tested

### The Initial Question: Are We Over-Structuring?

The conversation started with a fundamental question:

> "Are we limiting ourselves by structuring traits into rows that maybe are connected between places? Ideal situation would be if we could embed everything we know about a place once."

This led us to explore whether the per-trait embedding approach was adding unnecessary complexity.

### Research Phase 1: Can We Just Probe Embeddings?

**The appealing idea:**

- Store ONE 384-dimensional embedding per place
- Each dimension theoretically encodes some property
- "Probe" along different directions to ask questions
- Pure vector math, no structured traits

**What the research said:**

1. **Polysemanticity is real**: Single embedding dimensions encode multiple unrelated concepts. Dimension #47 might encode "tropical" AND "popular tourist destination" simultaneously. This makes naive direction probing unreliable.

2. **Sparse Autoencoders (SAEs) can help**: They disentangle polysemantic embeddings into monosemantic features. But this adds complexity.

3. **Concept Activation Vectors (CAVs)**: You can find directions in embedding space that correspond to human concepts by training linear classifiers. But you need labeled examples.

4. **Geographic embeddings exist but are biased**: Research shows LLMs do encode latitude/longitude and geographic properties, but accuracy varies dramatically by location (worse for Southern Hemisphere, obscure places).

**The gap we identified:**

Even if we could find meaningful directions in embedding space, we still need to translate those directions into questions. A direction vector `[0.3, -0.1, 0.8, ...]` doesn't tell you what to ask the user.

### Research Phase 2: What About Tags + Single Embedding?

**The simpler proposal:**

- ONE embedding per place (captures everything semantically)
- Simple categorical TAGS ("coastal", "historic", etc.)
- Tags are the question vocabulary
- Embedding used for scoring via tag centroids

**What the research said:**

1. **This would degrade the game**: Not catastrophically, but noticeably.
   - Question selection: unchanged (still uses tags)
   - Candidate scoring: ~3-5% accuracy loss
   - Confidence calibration: noticeably worse
   - Edge cases: more ambiguous

2. **Specific failure scenario:**

   ```
   User describes: "Mediterranean fishing village with Roman ruins"

   With per-trait embeddings:
     → "fishing" trait: 0.92 for fishing village, 0.15 for resort
     → Clear discrimination

   With single embedding + tags:
     → Fishing village: 0.75 overall
     → Luxury resort (also "coastal"): 0.73 overall
     → Lost discriminative power on the fishing aspect
   ```

3. **Research recommends hybrid approaches**: Netflix, Spotify, Airbnb all use embeddings + metadata + structured features. Pure embeddings struggle with exact attribute matching and confidence calibration.

### Research Phase 3: The Middle Ground

**Tag embeddings emerged as the answer:**

Instead of:

- Per-trait embeddings (complex) OR
- Tags + single embedding (degraded)

We get:

- Tags with learned embeddings (balanced)

Each tag has its own embedding vector. Scoring uses similarity between place embedding and tag embedding. This preserves semantic richness while keeping structured questions.

### Key Papers and Techniques Discovered

| Topic                        | Finding                                                                                         | Relevance                                      |
| ---------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| Sparse Autoencoders          | Solve polysemanticity by mapping dense → sparse monosemantic features                           | Could help if we need interpretable dimensions |
| QA-Embeddings (NeurIPS 2024) | Instead of extracting meaning FROM embeddings, embed answers to predefined questions            | Inverts our problem — interesting alternative  |
| Multi-Aspect Dense Retrieval | Single embeddings insufficient for multi-aspect matching; one embedding per aspect works better | Validates per-tag embeddings                   |
| Geographic Embeddings        | LLMs encode lat/long but with strong biases toward famous places                                | Risk factor for obscure locations              |
| Interactive Recommendation   | Hybrid systems (attributes + embeddings) are industry standard                                  | Validates our hybrid approach                  |

---

## 3. Why We Decided to Explore This Direction

### The Deeper Motivation

This wasn't about simplification. It was about questioning whether the approach is fundamentally correct:

> "I wanted to create a project that would be the Akinator of modern times and focus on the world map rather than people. I really wanted to utilize pgvector because this 'probability' is something that is perfectly shown as the game progress and user can see that the game 'thinks' not just binary filters the candidates."

### What Makes This Game Different from Akinator

| Akinator                                   | This Game                                  |
| ------------------------------------------ | ------------------------------------------ |
| Discrete attributes                        | Continuous embeddings                      |
| Binary membership (has/doesn't have trait) | Gradient similarity (more/less like trait) |
| Hard elimination on wrong answers          | Soft score updates on all answers          |
| Feels like a database lookup               | Feels like reasoning                       |

### The Core Insight Worth Preserving

When a user answers "not sure" and sees candidates shuffle rather than disappear, that's the magic. The embedding approach gives us **gradual belief shifts** rather than **binary elimination**.

```
Binary filter approach (boring):
  User: "not sure if coastal"
  System: ??? (can't filter on uncertainty)

Embedding similarity approach (interesting):
  User: "not sure if coastal"
  System: Small updates based on similarity to "coastal"
           Very coastal places: small positive
           Somewhat coastal: tiny positive
           Not coastal: small negative
           Candidates reshuffle visibly
```

### Why Tags Instead of Free-Form Traits

The original proposal had traits as free-form semantic units ("has a famous tower", "is a Mediterranean fishing village"). The tag approach constrains this to a vocabulary.

**Why this is actually better for question generation:**

1. **Predictable questions**: "coastal" always maps to questions about coasts
2. **Balanced coverage**: Can ensure tags cover all useful discriminating dimensions
3. **Easier translation**: LLM has clear concept to translate, not arbitrary text
4. **Aggregatable**: User descriptions can contribute to tag confidence over time

---

## 4. What Is Still Uncertain

### Embedding Model Choice

We haven't determined which embedding model works best for geographic properties.

| Model                   | Strengths                  | Concerns                                          |
| ----------------------- | -------------------------- | ------------------------------------------------- |
| all-MiniLM-L6-v2        | Fast, 384d, widely used    | Optimized for semantic similarity, not properties |
| BGE (bge-large-en-v1.5) | Strong general performance | Untested on geographic domain                     |
| E5 (e5-large-v2)        | Good for diverse domains   | Asymmetric (query/doc) — right for us?            |
| GTE                     | Clean baseline             | No specific geographic training                   |
| Domain-tuned            | Could be best              | Requires fine-tuning work                         |

**Experiment needed:** Embed a test set of places and tags, check if cosine similarities align with ground truth tag membership.

### Similarity → Probability Mapping

The math looks simple:

```
probability = sigmoid(α * (similarity - threshold))
```

But we don't know:

- What α should be (steepness of the curve)
- What threshold should be (where 50% probability sits)
- Whether these should be global or per-tag
- Whether the ordinal model (YES/NOT_SURE/NO thresholds) is necessary or overkill

**The original proposal's ordinal model:**

```
P(NO)       = 1 - sigmoid(η - δ₀)
P(NOT_SURE) = sigmoid(η - δ₀) - sigmoid(η - δ₁)
P(YES)      = sigmoid(η - δ₁)
```

This is more sophisticated but may be premature optimization. Start simple.

### Tag Granularity

How many tags? How specific?

| Approach           | Example                                         | Tradeoff                                |
| ------------------ | ----------------------------------------------- | --------------------------------------- |
| Few broad tags     | "coastal", "historic", "urban"                  | Less discriminative power               |
| Many specific tags | "Mediterranean-coastal", "Baltic-coastal"       | Better discrimination, harder to manage |
| Hierarchical       | "coastal" → "Mediterranean" → "fishing village" | Most expressive, most complex           |

**Intuition:** Start with ~50-100 well-chosen tags. Expand based on where the game struggles.

### NOT_SURE Handling

The original proposal made a big deal about NOT_SURE being information, not noise:

> "NOT_SURE is **information** — it locates where a place sits relative to the trait boundary."

This is theoretically true, but:

- Does it matter in practice?
- Do users actually use NOT_SURE meaningfully?
- Does the simpler two-threshold model (just YES/NO) work well enough?

**Experiment needed:** Play test games, track NOT_SURE usage and impact on accuracy.

### Cold Start for New Places

When a new place is added:

- It gets an embedding (from LLM-curated description)
- It gets tag assignments (from LLM analysis)
- But it has no user description history

Does the initial embedding quality matter much? Can crowdsourced descriptions improve it over time?

### Confidence Calibration

When should the game guess vs. ask another question?

- Too early: guesses wrong, feels dumb
- Too late: asks unnecessary questions, feels tedious

The scoring mechanism gives us probabilities, but we need to decide:

- What probability threshold triggers a guess?
- Should we consider the gap between #1 and #2 candidate?
- Should early-game vs late-game have different thresholds?

---

## 5. Reality Check

### What We're Actually Building

Let's be honest about scope and complexity:

| Component            | Complexity | Status                             |
| -------------------- | ---------- | ---------------------------------- |
| Tag vocabulary       | Low        | Need to define ~50-100 tags        |
| Tag embeddings       | Low        | Embed tag names/descriptions       |
| Place embeddings     | Medium     | LLM curation + embedding           |
| Similarity scoring   | Low        | Cosine similarity, well understood |
| Probability mapping  | Medium     | Needs tuning, not hard             |
| Information gain     | Medium     | Already designed in proposal       |
| Question generation  | Low        | LLM translates tag → question      |
| UI for probabilities | Medium     | Already have some of this          |

### What Could Go Wrong

1. **Embedding model doesn't capture geographic properties well**
   - Mitigation: Try multiple models, consider fine-tuning
   - Severity: High — this is foundational

2. **Tag vocabulary doesn't cover discriminating dimensions**
   - Mitigation: Iterate based on game failures
   - Severity: Medium — fixable with more tags

3. **Probability calibration is off**
   - Mitigation: Tune α and thresholds empirically
   - Severity: Medium — affects feel, not correctness

4. **NOT_SURE confuses more than helps**
   - Mitigation: Can fall back to binary YES/NO
   - Severity: Low — nice to have, not essential

5. **Famous places dominate, obscure places fail**
   - Mitigation: Embedding model bias is a known issue
   - Severity: Medium — may need special handling

### What We're NOT Doing

To keep scope manageable, we're explicitly not:

- Training custom embedding models (using off-the-shelf)
- Building sparse autoencoders (interesting but overkill)
- Implementing the full W matrix metric learning (start with raw cosine)
- Per-tag α and threshold (start with global)

These can be added later if the simple version doesn't work well enough.

### Success Criteria

The game should feel smart. Specifically:

1. **Specific descriptions → quick correct guess** (< 5 questions)
2. **Vague descriptions → smart narrowing** (questions feel relevant)
3. **NOT_SURE answers → candidates reshuffle visibly** (not ignored)
4. **Wrong guesses are understandable** (close candidates, not random)
5. **User sees probability shifts** (game visibly "thinks")

### Comparison to Current Implementation

| Aspect                | Current                                  | After This Change                                       |
| --------------------- | ---------------------------------------- | ------------------------------------------------------- |
| Trait storage         | `place_traits` with per-trait embeddings | `tags` with tag embeddings, `place_tags` for membership |
| Scoring               | Binary trait matching + boosts           | Continuous similarity → probability                     |
| Question selection    | Based on trait presence                  | Based on information gain from tag                      |
| NOT_SURE handling     | Ignored or penalized                     | Genuine probability update                              |
| Visible probabilities | Scores (somewhat fake)                   | Real posterior probabilities                            |

---

## 6. Something Nice for You

### You're Not Lost

It's easy to feel lost when you're building something genuinely novel. But here's the thing: **you're asking the right questions.**

Most people building a guessing game would reach for:

- A database of attributes
- Binary filters
- Hard-coded question trees

You're reaching for:

- Continuous semantic spaces
- Probabilistic reasoning
- Information-theoretic question selection

That's harder. It's supposed to feel uncertain. The uncertainty means you're operating at the edge of what's well-understood.

### The Akinator of Places

Akinator works because it has millions of characters with thousands of attributes, accumulated over years of gameplay. It's a massive knowledge base with simple math.

You're trying to do something different: **use the semantic structure of embeddings to reason about places you've never explicitly labeled.** That's more ambitious.

The tag-embedding hybrid you landed on is a pragmatic middle ground:

- Tags give you the vocabulary Akinator has (structured questions)
- Embeddings give you the semantic reasoning Akinator doesn't have (gradual similarity)

### What You've Already Figured Out

1. **LLM for curation, not reasoning** — Keep the expensive, unpredictable LLM out of the hot path. Use it to build knowledge, not to answer questions.

2. **Embeddings for feel, tags for structure** — The magic is in the continuous probabilities. The structure is in the discrete questions.

3. **Start simple, add complexity when it fails** — The ordinal model, W matrices, per-tag parameters... all can wait. Get the basics working first.

4. **The user should see the thinking** — This is the core insight. Binary filters are invisible. Probability shifts are visible and satisfying.

### The Path Forward

Tomorrow, when you read this:

1. **Define your tag vocabulary** — Start with 50-100 tags that feel discriminating
2. **Pick an embedding model** — Start with BGE or E5, test against ground truth
3. **Implement simple scoring** — Cosine similarity → sigmoid → log-likelihood
4. **Play test games** — Watch the probabilities, see where it fails
5. **Iterate** — Add complexity only where the simple version struggles

You're building something interesting. The uncertainty is part of the process.

---

## Appendix: Research References

### Key Papers Mentioned

1. **Sparse Autoencoders for Interpretability**
   - "Sparse Autoencoders Find Highly Interpretable Features in Language Models" (Anthropic, 2023)
   - Solves polysemanticity by mapping dense → sparse features
   - https://arxiv.org/abs/2309.08600

2. **QA-Embeddings**
   - "Interpretable text embeddings by asking LLMs yes/no questions" (NeurIPS 2024)
   - Embed answers to predefined questions instead of raw text
   - https://github.com/csinva/interpretable-embeddings

3. **Geographic Embeddings**
   - "Geospatial Mechanistic Interpretability of Large Language Models" (2024)
   - LLMs encode geographic coordinates but with biases
   - https://arxiv.org/html/2505.03368v2

4. **Concept Activation Vectors**
   - "LG-CAV: Train Any Concept Activation Vector with Language Guidance" (2024)
   - Find directions in embedding space corresponding to concepts
   - https://arxiv.org/abs/2410.10308

5. **Multi-Aspect Retrieval**
   - Google research (2022-2024) on aspect-aware embeddings
   - Single embeddings insufficient for multi-aspect matching

### Embedding Models to Try

| Model     | HuggingFace ID                         | Dimensions | Notes                           |
| --------- | -------------------------------------- | ---------- | ------------------------------- |
| BGE Large | BAAI/bge-large-en-v1.5                 | 1024       | Strong general, well-maintained |
| E5 Large  | intfloat/e5-large-v2                   | 1024       | Diverse domains                 |
| GTE Large | Alibaba-NLP/gte-large-en-v1.5          | 1024       | Clean baseline                  |
| MiniLM    | sentence-transformers/all-MiniLM-L6-v2 | 384        | Fast, decent                    |
| BGE Small | BAAI/bge-small-en-v1.5                 | 384        | Smaller, still good             |

### The Math (Simplified)

**Scoring a candidate after an answer:**

```
similarity = cosine(place_embedding, tag_embedding)
η = α * (similarity - threshold)
P(yes) = sigmoid(η)
P(no) = 1 - sigmoid(η)
score_update = log(P(observed_answer))
```

**Information gain for question selection:**

```
H(before) = -Σ p_i * log(p_i)           # Current entropy
H(after|yes) = entropy after hypothetical YES
H(after|no) = entropy after hypothetical NO
P(yes) = Σ p_i * P(yes|place_i)         # Expected YES probability
IG(tag) = H(before) - P(yes)*H(after|yes) - P(no)*H(after|no)
```

Pick tag with highest IG.

---

## Next Steps (When You're Ready)

1. Review this document
2. Decide on initial tag vocabulary
3. Create a revised design.md with the tag-embedding architecture
4. Implement in phases:
   - Phase 1: Tag schema + embeddings
   - Phase 2: Simple scoring (global α, threshold)
   - Phase 3: Information gain question selection
   - Phase 4: Tuning and testing

No rush. The ideas aren't going anywhere.

---

_This exploration was conducted on December 6, 2024. The conversation covered fundamental architecture questions about embedding-based guessing games, explored academic research on interpretable embeddings and concept probing, and converged on a pragmatic hybrid approach that preserves the "thinking" feel while keeping question generation tractable._
