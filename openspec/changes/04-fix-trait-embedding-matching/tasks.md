## 1. Function Updates

- [x] 1.1 Modify `get_semantic_questions()` to calculate pgvector similarity between places and traits
- [x] 1.2 Replace `LEFT JOIN place_traits` with similarity-based match determination
- [x] 1.3 Use `<=>` (cosine distance) or `<#>` (inner product) operator for similarity
- [x] 1.4 Apply `match_threshold` from config to determine "has trait" status

## 2. Algorithm Adjustments

- [x] 2.1 Modify `adjust_candidates_for_answer()` to use similarity-based matching
- [x] 2.2 Calculate match_strength as similarity score (not binary)
- [x] 2.3 Apply match zone thresholds (strong/partial/weak) based on similarity

## 3. Performance

- [x] 3.1 Add pgvector index on `places.embedding` if not exists - exists via embeddings table
- [x] 3.2 Add pgvector index on `traits.embedding` if not exists - exists via embeddings table
- [ ] 3.3 Test query performance with 1000+ candidates

## 4. Testing

- [ ] 4.1 Add pgTAP test for similarity-based trait matching
- [ ] 4.2 Test match zone classification (strong/partial/weak)
- [ ] 4.3 Compare question quality before/after change
