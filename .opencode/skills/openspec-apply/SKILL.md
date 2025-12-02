---
name: openspec-apply
description: >-
  Use when implementing an APPROVED OpenSpec change. Read tasks.md and follow
  EXACTLY. Do not deviate, add features, or skip tasks. Use with test-tdd for
  each code task.
---

# OpenSpec Apply

Implement approved changes by following the task list exactly.

> **Announce:** "I'm using openspec-apply to implement change [id] following the approved tasks."

## Iron Law

```
FOLLOW THE TASK LIST EXACTLY - NO ADDITIONS, NO SKIPS
```

The tasks were approved. Your job is to execute them, not improve them.

## Process

### Phase 1: Load Context

1. Read the proposal:
   ```bash
   openspec show [change-id]
   ```

2. Read `tasks.md` completely before starting

3. Identify current progress:
   - Which tasks are `[x]` complete?
   - Which is the next `[ ]` pending task?

### Phase 2: Execute Tasks

For EACH task:

**Step 1: Announce**
```
Starting Task N.M: [task description]
```

**Step 2: Load TDD skill**
→ REQUIRED SUB-SKILL: Load `test-tdd` for any code task

**Step 3: Follow task steps exactly**
- Create/modify the exact files listed
- Write the exact code specified
- Run the exact verification commands

**Step 4: Verify**
- Test passes?
- No other tests broken?
- Types check?

**Step 5: Mark complete**
Update `tasks.md`: `- [ ]` → `- [x]`

**Step 6: Commit**
```bash
git add [files]
git commit -m "[type](scope): [description]"
```

### Phase 3: Report Progress

After each task:
```
Completed Task N.M: [description]
- Files changed: [list]
- Tests: PASS
- Next: Task N.M+1
```

### Phase 4: Completion

When all tasks are `[x]`:

1. Run full verification:
   ```bash
   bun run type-check
   bun run lint
   bun test
   supabase test db
   ```

2. Report:
   ```
   All tasks complete for change [id].
   - [X] tasks completed
   - All tests passing
   - Ready for code review
   ```

3. Load `code-review` skill for final review

## Working with Subagents

If dispatching domain experts:

1. Load `subagent-workflow` skill
2. Give them the specific task from tasks.md
3. Track their session_id
4. Verify their output
5. If issues found, recall their session for fixes

## REQUIRED SUB-SKILL

- For any code task → Load `test-tdd`
- For subagent orchestration → Load `subagent-workflow`
- After completion → Load `code-review`

## Red Flags - STOP

If you catch yourself:
- Adding features not in tasks
- Skipping tasks "to save time"
- Implementing differently than specified
- Not running verification steps
- Marking tasks complete without verification

STOP. Follow the task list.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I see a better way" | The plan was approved. Follow it. |
| "This task is unnecessary" | The plan was approved. Do it anyway. |
| "I'll combine these tasks" | Tasks are sized deliberately. Do them separately. |
| "Tests are passing, skip verification" | Run ALL verification. Every time. |

## What To Do When Stuck

If a task is unclear or blocked:

1. STOP - do not guess
2. State what's unclear
3. Ask for clarification
4. Wait for response

Do NOT proceed with assumptions.
