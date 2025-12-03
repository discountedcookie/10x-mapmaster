---
name: testing
description: >-
  Run tests before and after changes. Only add tests for complex logic,
  not boilerplate. Database tests matter most.
---

# Testing

Verify changes don't break things. Don't create test bloat.

> **Announce:** "I'm running tests to verify the changes."

## Philosophy

**Database (pgTAP):** This is where real logic lives. Test it thoroughly.

**Frontend (Vitest):** Thin RPC layer. Only test:
- Complex transformations
- Non-obvious edge cases
- NOT: "does this call that function"

## Workflow

**Before implementing:**
```bash
bun run test
```
If tests fail, fix them first.

**After implementing:**
```bash
bun run test
```
If tests fail, your change broke something. Fix it.

## When to Add Tests

**YES - add tests for:**
- New database functions with business logic
- Complex data transformations
- Non-obvious edge cases you discovered

**NO - don't test:**
- "Does this function call that function"
- Pinia store initialization
- Vue component mounting
- API calls with mocked responses
- Obvious behavior readable from code

## Commands

```bash
bun run test        # All tests (unit + db)
bun run test:unit   # Frontend only
bun run test:db     # Database only (pgTAP)
```

## If Tests Fail

1. Read the error message
2. Check if YOUR change caused it
3. If yes → fix your code
4. If no → fix the test or report the issue
