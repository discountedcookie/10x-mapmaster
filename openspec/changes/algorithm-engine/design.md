# Design: Algorithm Engine

## Execution Plan

1. **Scoring primitives** – Similarity helpers, probability conversion, config lookups.
2. **Confidence metrics** – Stored procedures to compute top_prob, margin, entropy.
3. **Trait matching** – Match strength calculation + power-law adjustments.
4. **Question selection** – Split quality calculation for semantic/geographic traits.
5. **Spatial filtering** – Encapsulate PostGIS filters for YES/NO answers.
6. **Tests + tuning** – pgTAP suites and seed configuration values.

## Dependencies

- Requires database foundation schema and config tables.
- Edge functions must exist for embeddings/LLM integration but can be mocked during tests.

## Agents

- **Primary:** @supabase-expert

## Risks & Mitigations

| Risk                          | Mitigation                                             |
| ----------------------------- | ------------------------------------------------------ |
| Performance on large datasets | Use indexes, limit candidate count via config          |
| Floating point drift          | Normalize vectors, keep calculations in SQL not client |
| Overfitting config            | Store defaults in seeds, document tuning guide         |
