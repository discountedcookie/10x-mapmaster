## REMOVED Requirements

### Requirement: LLM-Selected Questions

**Reason**: Violates architecture - LLM should not select questions, only phrase them. Function was dead code.

**Migration**: Use `select_best_question()` for algorithmic selection, then `generate_question_text()` (from change 01) for LLM phrasing.
