---
name: test-tdd
description: >-
  Use when implementing any feature or bugfix. Enforces test-first workflow.
  Automatically routes to correct test layer (pgTAP for DB, Vitest for frontend).
---

# Test-Driven Development

> **Announce:** "I'm using test-tdd for [layer] testing."

## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Code written before tests? Delete it. Start over.

## Step 1: Identify Your Layer

**What are you changing?**

| If changing... | Use | Command |
|----------------|-----|---------|
| Game logic, scoring, ranking, RLS, embeddings | **pgTAP** | `supabase test db` |
| Vue components, stores, composables | **Vitest** | `bun test [file]` |
| Full user flows (rare, cross-layer) | Playwright | `bun run test:e2e` |

**Database-first rule:** If it's game logic, it belongs in PostgreSQL → use pgTAP.

---

## pgTAP (Database)

For: game mechanics, scoring, ranking, RLS policies, embeddings.

### RED: Write Failing Test

Add test in `supabase/tests/*.sql`:

```sql
SELECT is(
  (SELECT result FROM my_function('input')),
  'expected',
  'my_function returns expected result'
);
```

### Verify RED

```bash
supabase test db
```

Confirm: Test FAILS because behavior is missing (not syntax error).

### GREEN: Minimal Implementation

Edit source files in `supabase/db/` (never edit migrations directly).

### Verify GREEN

```bash
supabase test db
```

Confirm: All tests pass.

---

## Vitest (Frontend)

For: Vue components, Pinia stores, composables, UI behavior.

### RED: Write Failing Test

Add test in `src/__tests__/**/*.spec.ts`:

```typescript
test('component shows loading state', () => {
  const { getByText } = render(MyComponent)
  expect(getByText('Loading...')).toBeInTheDocument()
})
```

### Verify RED

```bash
bun test src/__tests__/path/to/file.spec.ts
```

Confirm: Test FAILS because behavior is missing.

### GREEN: Minimal Implementation

Edit files in `src/`. Remember: NO game logic here - call `supabase.rpc()`.

### Verify GREEN

```bash
bun test src/__tests__/path/to/file.spec.ts
```

Confirm: Test passes.

---

## When to Skip E2E

Most changes do NOT need Playwright tests:

- **Unit behavior** → pgTAP or Vitest is sufficient
- **Bug fixes** → Add unit test that reproduces bug
- **New functions** → pgTAP for DB, Vitest for frontend

Use Playwright only for:
- Critical user flows (game start → answer → guess)
- Cross-layer regressions that unit tests can't catch

---

## Red Flags - STOP

If you catch yourself:
- Writing code before tests
- Test passes on first run (you're testing existing behavior)
- Changing test AND implementation together

STOP. Delete the implementation. Write the test first.

## Verification Checklist

Before declaring done:
- [ ] Test failed first (RED verified)
- [ ] Minimal code written to pass
- [ ] All tests pass (GREEN verified)
- [ ] No game logic in frontend
