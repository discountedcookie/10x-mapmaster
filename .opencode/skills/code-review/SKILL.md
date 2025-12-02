---
name: code-review
description: >-
  Use for quick self-review of small changes. For comprehensive review or
  cross-domain changes, dispatch @code-reviewer agent instead.
---

# Code Review

Review code for quality and compliance. Report findings.

> **Announce:** "I'm using code-review to review these changes before commit."

## This Skill vs @code-reviewer Agent

| Situation | Use |
|-----------|-----|
| Small change (< 100 lines) | This skill |
| Single domain (DB only or frontend only) | This skill |
| Quick sanity check before commit | This skill |
| Large change (> 300 lines) | Dispatch `@code-reviewer` |
| Cross-domain (DB + frontend) | Dispatch `@code-reviewer` |
| Security audit needed | Dispatch `@code-reviewer` |
| Need fresh eyes (you wrote the code) | Dispatch `@code-reviewer` |

To dispatch: Load `subagent-workflow` skill first.

## Iron Law

```
REPORT FINDINGS - DO NOT FIX
```

Your job is to identify issues. The main agent decides what to fix.

## Review Checklist

### 1. Architecture Compliance

**Database-First (from architecture rule):**
- [ ] Business logic is in PostgreSQL, not frontend?
- [ ] Frontend only calls `supabase.rpc()`, no direct queries?
- [ ] No game logic, scoring, or calculations in frontend?

**Source-Based Workflow:**
- [ ] Database changes are in `supabase/db/`, not migrations?
- [ ] Both source files AND migrations are included?

**Security:**
- [ ] RLS policies validate `auth.uid()`?
- [ ] SECURITY DEFINER functions check permissions?
- [ ] No sensitive data exposed in frontend state?

### 2. Spec Alignment

Run `openspec list --specs` and check:
- [ ] Does implementation match spec requirements?
- [ ] Are all scenarios covered?
- [ ] Any spec conflicts?

If change has associated proposal:
- [ ] Does implementation match `tasks.md`?
- [ ] All tasks completed?
- [ ] No unrequested changes?

### 3. Code Quality

**TypeScript:**
- [ ] Types are correct (not `any`)?
- [ ] Error handling present?
- [ ] No console.log left in?

**SQL:**
- [ ] Uppercase keywords, lowercase identifiers?
- [ ] Functions have proper error handling?
- [ ] Tests cover edge cases?

**Tests:**
- [ ] New code has tests?
- [ ] Tests verify behavior, not implementation?
- [ ] All tests passing?

### 4. Scope Compliance

Compare what was requested vs what was changed:
- [ ] Changes are within scope?
- [ ] No "while I was here" additions?
- [ ] No unrequested refactoring?

## Verification Commands

Run these and report results:

```bash
bun run type-check    # TypeScript
bun run lint          # ESLint
bun run test:db				# Database tests
bun run test:e2e			# End-to-end tests
bun run test:security # Security tests
bun run test:unit     # Unit tests
```

## Output Format

```markdown
## Code Review: [scope/description]

### Verdict: PASS | NEEDS CHANGES | BLOCKED

### Critical Issues (blocks merge)
- [ ] [Issue]: [Description] - [file:line]

### Major Issues (should fix)
- [ ] [Issue]: [Description] - [file:line]

### Minor Issues (nice to have)
- [ ] [Issue]: [Description] - [file:line]

### Observations
- [Non-blocking observations]

### Verification Results
- Type check: PASS/FAIL
- Lint: PASS/FAIL  
- Unit tests: PASS/FAIL
- DB tests: PASS/FAIL

### Spec Compliance
- [Spec checked]: Aligns / Conflicts
- Scope: Within bounds / Out of scope items: [list]
```

## Severity Definitions

| Severity | Definition | Action |
|----------|------------|--------|
| **Critical** | Breaks functionality, security issue, data loss risk | Must fix before merge |
| **Major** | Significant issue but not breaking | Should fix, discuss if controversial |
| **Minor** | Style, optimization, nice-to-have | Optional, note for future |

## What Happens Next

After review, the main agent will:

1. **PASS** → Proceed to commit/merge
2. **NEEDS CHANGES** → Recall implementing agent with session_id to fix issues
3. **BLOCKED** → Escalate for architectural discussion

## Red Flags - Note These

If you observe:
- Business logic in frontend
- Direct database queries (not RPC)
- Missing tests for new code
- Scope creep beyond task list
- Security patterns violated

Report them. Don't fix them.
