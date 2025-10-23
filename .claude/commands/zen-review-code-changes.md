# Review Code Changes

Comprehensive code review for Pull Requests covering logic, security, and architecture.

## Review Scope

**All pre-commit checks plus:**
- Code logic & correctness
- Test coverage
- Architectural adherence
- RLS/security changes (BLOCKING if schema modified)
- Performance impact

## Zen Delegation

Use `mcp_zen_codereview` with full analysis:

```javascript
mcp_zen_codereview({
  step: "Comprehensive PR code review",
  step_number: 1,
  total_steps: 2,
  next_step_required: true,
  findings: "Reviewing changes for logic, security, architecture...",
  relevant_files: [
    "/Users/ciaastek/Projects/Sirocco/10x-mapmaster/src/...",
    // All changed files (absolute paths)
  ],
  focus_on: "security", // or "performance", "quality"
  review_type: "full",
  model: "gemini-2.5-pro"
})
```

## Critical Security Review (BLOCKING)

**If `supabase/migrations/*.sql` modified:**
Trigger security audit:

```javascript
mcp_zen_secaudit({
  step: "RLS policy security review",
  step_number: 1,
  total_steps: 1,
  next_step_required: false,
  findings: "Analyzing RLS policy changes...",
  relevant_files: [
    "/Users/ciaastek/Projects/Sirocco/10x-mapmaster/supabase/migrations/000001_initial_schema.sql"
  ],
  audit_focus: "comprehensive",
  threat_level: "high",
  model: "gemini-2.5-pro"
})
```

**If `src/stores/auth.ts` modified:**
Review auth logic with security focus.

## Required Tests

```bash
npm run test:db              # BLOCKING for DB changes
npm run test:unit            # BLOCKING for unit tests
npm run test:e2e      # WARNING
```

## Review Output Format

### ✅ Strengths
What's well done

### ⚠️ Issues
- **BLOCKING**: Must fix before merge
- **WARNING**: Should fix
- **OPTIONAL**: Improvements

### 📝 Recommendations
Architecture, performance, security enhancements
