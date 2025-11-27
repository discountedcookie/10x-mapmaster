# Tasks: Add Candidate Scoring

- [x] Implement get_initial_candidates: compute similarity (cosine distance) between description embedding and place embeddings
- [x] Implement softmax_probabilities: convert scores to probabilities using temperature-scaled softmax
- [x] Apply initial candidate threshold and cap (configurable via parameters)
- [x] Inputs: description embedding_id; Outputs: candidate list with place_id, name, lat, lng, raw_score
- [x] Numerical stability in softmax (max subtraction before exp)
