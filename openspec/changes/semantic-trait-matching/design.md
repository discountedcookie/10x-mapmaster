# Design: Semantic Trait Matching

## Mathematical Model

### Variables

- `place_i` ∈ {1, ..., N} — candidate places
- `trait_q` ∈ {1, ..., Q} — traits (questions)
- `e_i` ∈ R^d — place embedding (aggregated from place's traits)
- `e_q` ∈ R^d — trait embedding
- `Y` ∈ {YES, NOT_SURE, NO} — answer

### Similarity Function

**Raw cosine** (baseline):

```
sim(i, q) = cos(e_i, e_q) = (e_i · e_q) / (||e_i|| ||e_q||)
```

**Learned metric** (optional):

```
sim_W(i, q) = (W e_i) · (W e_q) / (||W e_i|| ||W e_q||)
```

where W ∈ R^{k×d} is learned. Special cases:

- Diagonal W: k = d, W = diag(w₁, ..., w_d) — feature reweighting
- Low-rank W: k << d — learned subspace projection

**Place embedding aggregation** (soft top-k):

```
e_i = Σ_j w_j · e_{t_j}   where t_j are place i's traits

w_j = softmax(sim(e_q, e_{t_j}) · β)  over top-k by similarity
```

### Response Model (Graded Response / Ordinal)

For latent "trait applicability" η:

```
η(i, q) = α_q · (sim(i, q) - m_q)
```

Response probabilities (cumulative logit model):

```
P(Y ≥ NOT_SURE | η) = σ(η - δ₀)
P(Y ≥ YES | η)      = σ(η - δ₁)

Therefore:
P(Y = NO | η)        = 1 - σ(η - δ₀)
P(Y = NOT_SURE | η)  = σ(η - δ₀) - σ(η - δ₁)
P(Y = YES | η)       = σ(η - δ₁)

where δ₀ < δ₁ are thresholds, σ(x) = 1/(1 + e^{-x})
```

### Embedding-Parameterized Trait Parameters

Instead of per-trait (α_q, m_q) or global (α, m), predict from embeddings:

```
α_q = w_α · e_q + b_α
m_q = w_m · e_q + b_m
```

where w*α, w_m ∈ R^d and b*α, b_m ∈ R are learned.

**Intuition**:

- α_q (discrimination): How sharply does this trait separate places? Specific traits ("has a revolving restaurant") discriminate more than vague ones ("is famous").
- m_q (difficulty): How high must similarity be for YES? Abstract traits ("is historic") have lower thresholds than concrete ones ("has exactly 324 steps").

### Full Parameter Set

```
θ = {
  W ∈ R^{k×d},           # Metric transformation (optional)
  w_α, w_m ∈ R^d,        # Embedding → trait parameter maps
  b_α, b_m ∈ R,          # Intercepts
  δ₀, δ₁ ∈ R             # Ordinal thresholds (δ₀ < δ₁)
}
```

## Model Variations

### M0: Global Binary (Current Baseline)

```
P(Y = YES | sim) = σ(α(sim - m))
P(Y = NO | sim)  = 1 - σ(α(sim - m))
```

Parameters: {α, m}. Drops NOT_SURE. No per-trait structure.

### M1: Global Ordinal

```
P(Y | sim) = ordinal_model(α(sim - m), δ₀, δ₁)
```

Parameters: {α, m, δ₀, δ₁}. Uses NOT_SURE. No per-trait structure.

### M2: Per-Trait Ordinal

```
P(Y | sim, q) = ordinal_model(α_q(sim - m_q), δ₀, δ₁)
```

Parameters: {α_q, m_q}\_q ∪ {δ₀, δ₁}. Per-trait discrimination/difficulty. May overfit with limited data.

### M3: Embedding-Parameterized Ordinal

```
α_q = w_α · e_q + b_α
m_q = w_m · e_q + b_m
P(Y | sim, q) = ordinal_model(α_q(sim - m_q), δ₀, δ₁)
```

Parameters: {w*α, w_m, b*α, b_m, δ₀, δ₁}. New traits work automatically.

### M3+W: Full Model with Learned Metric

Add W to M3, use sim_W instead of sim.

## Metric Learning

### Diagonal W (Feature Reweighting)

```
W = diag(w₁, ..., w_d)
sim_W(i, q) = Σ_j w_j² · e_i[j] · e_q[j] / (normalization)
```

Interpretation: w_j² is the importance of embedding dimension j for geographic matching.

### Low-Rank W (Subspace Projection)

```
W ∈ R^{k×d}, k << d
sim_W(i, q) = (W e_i) · (W e_q) / (normalization)
```

Interpretation: Project to k-dimensional geography-relevant subspace.

### Geometry Analysis

After fitting W:

1. Extract principal directions of W (SVD)
2. Cluster traits by their W-transformed embeddings
3. Check if clusters correspond to geographic categories (coastal, historic, etc.)
4. Visualize place embeddings in W-transformed space

## Score Updates (Game Loop)

### State

For each place i, maintain log_score[i] (unnormalized log-posterior).

### Update Rule

On observing answer Y to trait q:

```sql
FOR each place i:
  η := α_q * (sim(i, q) - m_q)
  p := P(Y | η)  -- from ordinal model
  log_score[i] += ln(p)
```

### Probability Conversion

```sql
-- Normalize to probabilities
total := ln(Σ_i exp(log_score[i]))  -- log-sum-exp
probability[i] := exp(log_score[i] - total)
```

## Information Gain with Three Outcomes

### Current Entropy

```
H(now) = -Σ_i p_i · ln(p_i)
```

### Expected Entropy After Question q

For each possible answer y ∈ {YES, NOT_SURE, NO}:

```
P(Y = y) = Σ_i p_i · P(Y = y | place = i, trait = q)

-- Posterior after observing Y = y
p_i^{(y)} = p_i · P(Y = y | place = i, trait = q) / P(Y = y)

H(after | Y = y) = -Σ_i p_i^{(y)} · ln(p_i^{(y)})
```

Expected entropy:

```
E[H(after)] = Σ_{y ∈ {YES, NOT_SURE, NO}} P(Y = y) · H(after | Y = y)
```

Information gain:

```
IG(q) = H(now) - E[H(after)]
```

### Question Selection

Select trait q\* = argmax_q IG(q), excluding already-asked and redundant traits.

## Implementation Notes

### Ordinal Model in SQL

```sql
CREATE FUNCTION ordinal_prob(
  eta NUMERIC,
  delta_0 NUMERIC,
  delta_1 NUMERIC,
  answer TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE answer
    WHEN 'no' THEN 1 - (1 / (1 + exp(-(eta - delta_0))))
    WHEN 'not_sure' THEN
      (1 / (1 + exp(-(eta - delta_0)))) - (1 / (1 + exp(-(eta - delta_1))))
    WHEN 'yes' THEN 1 / (1 + exp(-(eta - delta_1)))
  END;
$$ LANGUAGE sql IMMUTABLE;
```

### Storing Transformed Embeddings

If using learned W:

```sql
-- Option 1: Store W-transformed embeddings
ALTER TABLE embeddings ADD COLUMN transformed vector(k);
UPDATE embeddings SET transformed = W @ embedding;

-- Option 2: Apply W at query time (slower but more flexible)
SELECT (W @ e1) <=> (W @ e2) as transformed_distance;
```

### Parameter Storage

```sql
-- Store fitted model parameters
INSERT INTO
  game_logic.config (key, value)
VALUES
  ('model.w_alpha', '[0.1, -0.2, ...]'), -- JSON array
  ('model.w_m', '[0.05, 0.1, ...]'),
  ('model.b_alpha', '1.5'),
  ('model.b_m', '0.3'),
  ('model.delta_0', '-0.5'),
  ('model.delta_1', '0.5'),
  ('metric.type', '"diagonal"'),
  ('metric.W', '[[...], [...], ...]');

-- JSON matrix
```

## Training Sketch

```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class SemanticScoring(nn.Module):
    def __init__(self, embed_dim, metric_type='cosine', metric_rank=None):
        super().__init__()
        self.w_alpha = nn.Parameter(torch.zeros(embed_dim))
        self.w_m = nn.Parameter(torch.zeros(embed_dim))
        self.b_alpha = nn.Parameter(torch.tensor(1.0))
        self.b_m = nn.Parameter(torch.tensor(0.0))
        self.delta_0 = nn.Parameter(torch.tensor(-0.5))
        self.delta_1 = nn.Parameter(torch.tensor(0.5))

        self.metric_type = metric_type
        if metric_type == 'diagonal':
            self.W_diag = nn.Parameter(torch.ones(embed_dim))
        elif metric_type == 'low_rank':
            self.W = nn.Parameter(torch.eye(metric_rank, embed_dim))

    def similarity(self, e_place, e_trait):
        if self.metric_type == 'diagonal':
            e_place = e_place * self.W_diag
            e_trait = e_trait * self.W_diag
        elif self.metric_type == 'low_rank':
            e_place = e_place @ self.W.T
            e_trait = e_trait @ self.W.T
        return F.cosine_similarity(e_place, e_trait, dim=-1)

    def forward(self, e_place, e_trait, answer):
        sim = self.similarity(e_place, e_trait)

        # Embedding-parameterized trait parameters
        alpha_q = (self.w_alpha * e_trait).sum(-1) + self.b_alpha
        m_q = (self.w_m * e_trait).sum(-1) + self.b_m

        eta = alpha_q * (sim - m_q)

        # Ordinal probabilities
        p_geq_ns = torch.sigmoid(eta - self.delta_0)
        p_geq_yes = torch.sigmoid(eta - self.delta_1)

        p_no = 1 - p_geq_ns
        p_ns = p_geq_ns - p_geq_yes
        p_yes = p_geq_yes

        # Return log-prob of observed answer
        probs = torch.stack([p_no, p_ns, p_yes], dim=-1)
        answer_idx = {'no': 0, 'not_sure': 1, 'yes': 2}
        return torch.log(probs[..., answer_idx[answer]] + 1e-8)

# Training loop sketch
model = SemanticScoring(embed_dim=768, metric_type='diagonal')
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

for batch in game_data:
    log_prob = model(batch['e_place'], batch['e_trait'], batch['answer'])
    loss = -log_prob.mean()
    loss.backward()
    optimizer.step()
    optimizer.zero_grad()
```

## Comparison Approach

Try variations and see what works:

1. Start with M1 (global ordinal) — does NOT_SURE help at all?
2. Add embedding-parameterized (M3) — do new traits work?
3. Try metric variations — does learned similarity help?

Keep what improves the game feel, drop what doesn't.
