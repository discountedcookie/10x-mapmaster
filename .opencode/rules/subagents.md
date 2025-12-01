# Subagent Workflow

This guide helps the main agent (Build/Plan) understand and effectively use subagents.

## Available Subagents

### @supabase-expert

**When to invoke:**
- Database schema changes (tables, columns, indexes)
- SQL function creation or modification
- RLS policy implementation
- PostGIS geographic operations
- pgvector embedding operations
- Migration workflow issues

**What it knows:**
- Source-based workflow (`supabase/db/` → `db:rebuild` → `test db`)
- This project's schema structure
- RLS validation patterns
- Game logic ownership (it owns ALL business logic)

**What it does NOT know:**
- Frontend code or patterns
- Vue/TypeScript specifics
- UI/UX considerations

**Tools available:** bash (db commands), edit, write, read, sequential-thinking

**Output format:** Changes made + Issues found (not fixed)

---

### @frontend-expert

**When to invoke:**
- Vue 3 component creation or modification
- shadcn-vue UI implementation
- Pinia store updates (reactive state only)
- Composable creation
- Frontend error handling for RPC calls

**What it knows:**
- Vue 3 Composition API patterns
- shadcn-vue component library
- This project's component structure (`src/components/`, `src/views/`)
- How to call `supabase.rpc()` properly

**What it does NOT know:**
- Database internals or SQL
- Game logic (it will refuse to implement it)
- Backend/edge function code

**Tools available:** bash (lint/test only), edit, write, read

**Output format:** Changes made + Issues found (not fixed)

---

### @code-reviewer

**When to invoke:**
- After significant code changes (yours or another subagent's)
- Before commits to validate architecture compliance
- When verifying a subagent did what was asked (scope compliance)
- Security review of new RLS policies or auth code

**What it knows:**
- Database-first architecture rules
- Source-based workflow expectations
- Code quality standards (types, error handling)
- Security patterns (RLS, auth validation)

**What it does NOT do:**
- Make changes (read-only)
- Fix issues (only reports them)
- Decide what to fix (user decides)

**Tools available:** read, glob, grep, list, sequential-thinking

**Output format:** PASS/FAIL + Critical/Major/Minor issues + Recommendations

---

### @researcher

**When to invoke:**
- Technical questions requiring external documentation
- Exploring implementation approaches with tradeoffs
- Understanding library/framework capabilities
- Comparing solutions before implementation

**What it knows:**
- Project stack (Vue 3, Supabase, MapLibre, deck.gl)
- Database-first architecture context
- How to search codebase first, then external docs

**What it does NOT do:**
- Make changes (read-only)
- Implement solutions (only researches)

**Tools available:** read, glob, grep, webfetch, exa search, sequential-thinking

**Output format:** Summary, Recommended Approach, Alternatives, Implementation Notes, References

---

### @player

**When to invoke:**
- Manual gameplay testing via browser
- Validating user flows (start game, answer questions, make guesses)
- Checking UI responsiveness and feedback
- Capturing console/network errors during play

**What it knows:**
- Game flow from `docs/architecture/gameplay.md`
- Expected UI behaviors (loading states, error display)
- How to use Chrome DevTools for observation

**What it does NOT do:**
- Read or modify code
- Access filesystem
- Run any commands

**Tools available:** chrome-devtools_* only

**Output format:** Repro steps + Expected vs Actual behavior

---

## Invocation Guidelines

### Before Invoking a Subagent

1. **Check this guide** - Is this the right subagent for the task?
2. **Scope the task** - Give a specific, bounded task, not a vague goal
3. **Provide context** - What files are relevant? What's the expected outcome?

### Prompt Structure for Subagents

```
TASK: [One clear sentence describing what to do]

CONTEXT:
- Relevant files: [list paths]
- Current state: [what exists now]
- Expected outcome: [what should exist after]

CONSTRAINTS:
- [Any specific limitations or requirements]
```

### After Subagent Returns

1. **Review "Changes made"** - Did it do what you asked?
2. **Check "Issues found"** - Are any critical enough to address now?
3. **Consider @code-reviewer** - For significant changes, verify with reviewer
4. **Report to user** - Summarize what was done, don't just pass through raw output

### Common Mistakes to Avoid

| Mistake | Why It's Bad | Do Instead |
|---------|--------------|------------|
| Invoking @frontend-expert for game logic | It will refuse or flag it | Use @supabase-expert |
| Invoking @supabase-expert for UI | Wrong domain expertise | Use @frontend-expert |
| Trusting subagent summaries blindly | They have blind spots | Verify with @code-reviewer |
| Acting on @code-reviewer findings immediately | User should decide | Present findings, wait for approval |
| Giving vague tasks | Subagents work best with specific scope | Be explicit about files and outcomes |

### Parallel vs Sequential

- **Parallel OK:** Research + planning tasks that don't depend on each other
- **Sequential required:** Implementation tasks that build on each other
- **Never parallel:** Multiple agents editing the same files
