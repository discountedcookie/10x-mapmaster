## Reduce MAX_QUESTIONS to 5

**Decision**: Reduce maximum questions per game from 10 to 5.

**Context**: Testing showed 1-2 questions sufficient for well-described places with good embeddings.

**Result**: Faster, more engaging games without sacrificing accuracy.

---

## Question Flow After Wrong Guess

**Decision**: Require at least one question after rejecting a high-confidence guess.

**Problem**: Users rejecting initial guesses saw immediate second guesses without engagement.

**Solution**: State machine enforces question before next guess via `mustAskQuestion` flag.

**Benefits**:
- Better user engagement
- Collects more learning data
- Gives system chance to narrow candidates

---

## Vector Embeddings Over Descriptors

**Decision**: Use full vector embeddings (384D gte-small) instead of simple descriptor filtering.

**Rationale**:
- More accurate semantic matching
- Handles creative/ambiguous descriptions
- Enables true learning from player descriptions
- Provides confidence scores for intelligent guessing

**Trade-offs**:
- More complex implementation (Edge Function required)
- Slightly higher latency
- Acceptable for significantly better accuracy (87-100% on clear descriptions)

---

## Confidence Threshold (70%)

**Decision**: Set `MIN_CONFIDENCE = 0.7` for showing guesses without questions.

**Rationale**:
- Balance between accuracy and user experience
- Lower threshold → too many wrong guesses
- Higher threshold → unnecessary questions
- 70% proven reliable in testing

---

## Cold Start with Seed Data

**Decision**: Include 20 famous places as seed data.

**Trade-off**: Violates pure "cold start" principle but provides better first-time experience and demonstrates capabilities immediately.

**Status**: Acceptable for MVP, system designed to grow organically from player contributions.
