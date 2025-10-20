# Design Decisions Log

## Pre-Deployment Polish

**Decision**: Comprehensive UX and security improvements before production deployment.

**Changes Implemented**:
1. **Toast Notifications**: Replaced all `alert()` with shadcn-vue Sonner toasts
   - Better UX, dismissible, non-blocking
   - Success/error variants with descriptions
   
2. **Input Validation**: 10-500 character limits with real-time feedback
   - Prevents empty/meaningless descriptions
   - Avoids token limit issues with Edge Function
   - Character counter provides visual feedback

3. **Rate Limiting**: Client-side protection (2-second cooldown, 50 requests/session)
   - Prevents accidental API abuse
   - User-friendly error messages
   - Note: Server-side rate limiting recommended for production

4. **Loading States**: Enhanced with spinner overlay and descriptive messages
   - "Analyzing your description..." during embedding generation
   - Improves perceived performance

5. **Accessibility**: ARIA labels on interactive map markers
   - `role="button"` and `aria-label` attributes
   - Reka UI provides built-in accessibility for all components

6. **Code Quality**: Fixed TypeScript recursion error, extracted constants, added JSDoc
   - TS2589 fixed with explicit type annotations
   - Magic numbers moved to configuration constants
   - Comprehensive documentation for complex functions

**Rationale**: Balanced polish for week-long deployment timeline. Focused on user experience, security, and code quality without over-engineering.

---

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
