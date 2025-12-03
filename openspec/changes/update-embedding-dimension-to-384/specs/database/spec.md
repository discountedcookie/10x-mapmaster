## MODIFIED Requirements

### Requirement: Embeddings Storage

The system SHALL store text embeddings with required constraints and indexes for semantic similarity.

#### Scenario: Embedding persistence

- **WHEN** an embedding is stored
- **THEN** it records id, source_text, 384d vector, and timestamps

#### Scenario: Indexing

- **WHEN** querying embeddings by similarity
- **THEN** an HNSW index exists on the embedding column using vector_ip_ops

#### Scenario: Access control

- **WHEN** accessing embeddings
- **THEN** only authorized functions/service_role can read/write embeddings per RLS/policies
