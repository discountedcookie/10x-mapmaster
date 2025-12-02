---
name: task-planning
description: >-
  Use after proposal approval to break work into 2-5 minute tasks with exact
  file paths and code examples. Each task must be completable by an agent with
  zero context. Do NOT use before proposal is approved.
---

# Task Planning

Break approved work into bite-sized, unambiguous tasks.

> **Announce:** "I'm using task-planning to create detailed implementation tasks."

## Iron Law

```
EACH TASK MUST BE COMPLETABLE IN 2-5 MINUTES WITH ZERO CONTEXT
```

Assume the implementing agent:
- Has never seen this codebase
- Doesn't know your reasoning
- Will follow instructions literally
- Needs exact file paths and code

## Task Structure

```markdown
### Task N.M: [Specific action]

**Files:**
- Create: `exact/path/to/new-file.ts`
- Modify: `exact/path/to/existing.ts:42-58`
- Test: `exact/path/to/test.spec.ts`

**Step 1: Write failing test**

```typescript
// exact code to add
test('specific behavior', () => {
  const result = functionName(input);
  expect(result).toBe(expected);
});
```

**Step 2: Verify test fails**

Run: `bun test path/to/test.spec.ts`
Expected: FAIL with "functionName is not defined"

**Step 3: Implement**

```typescript
// exact code to add
export function functionName(input: Type): ReturnType {
  return expected;
}
```

**Step 4: Verify test passes**

Run: `bun test path/to/test.spec.ts`
Expected: PASS

**Step 5: Commit**

```bash
git add path/to/files
git commit -m "feat(scope): specific change"
```
```

## Task Categories

Group tasks by domain:

```markdown
## 1. Database Schema
- [ ] 1.1 Add column X to table Y
- [ ] 1.2 Create RLS policy for Z

## 2. Database Functions
- [ ] 2.1 Create function A
- [ ] 2.2 Modify function B

## 3. Frontend Components
- [ ] 3.1 Create component X
- [ ] 3.2 Update store Y

## 4. Integration
- [ ] 4.1 Wire frontend to new function
- [ ] 4.2 Add E2E test
```

## Task Ordering

1. **Database first** - Schema, then functions
2. **Tests alongside** - Each implementation task includes test
3. **Frontend after backend** - Don't build UI for non-existent data
4. **Integration last** - Wire things together

## Verification Commands

Every task includes verification:

| Layer | Command | Expected |
|-------|---------|----------|
| Database | `supabase test db` | All tests pass |
| Frontend unit | `bun test [file]` | Specific test passes |
| E2E | `bun run test:e2e` | Flow works |
| Types | `bun run type-check` | No errors |
| Lint | `bun run lint` | No errors |

## REQUIRED SUB-SKILL

Tasks ready → Load `openspec-apply` to begin implementation

Each code task → Load `test-tdd` for the implementation

## Red Flags - STOP

If you catch yourself:
- Writing tasks like "implement the feature"
- Missing exact file paths
- Missing verification steps
- Tasks longer than 5 minutes
- Skipping test steps

STOP. Break it down further.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The agent will figure it out" | They won't. Be explicit. |
| "Too much detail is patronizing" | Too little detail causes errors. |
| "This task is obvious" | Obvious to you ≠ obvious to fresh agent. |
| "I'll explain if they get stuck" | They can't ask you. Write it down. |
