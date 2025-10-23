# Analyze Security Impact

Focused security review for authentication, RLS policies, and sensitive changes.

## When to Use

- Modifications to `supabase/migrations/*.sql`
- Changes to `src/stores/auth.ts`
- New external API integrations
- User input handling changes

## Security Review Checklist

### RLS Policies (BLOCKING)
- Policies not weakened or removed
- New tables have RLS enabled
- User isolation maintained
- Service role access controlled

### Authentication (BLOCKING)
- Session management secure
- Token handling proper
- Email verification enforced

### Input Validation
- User input sanitized
- SQL injection prevented
- XSS vulnerabilities eliminated
- Vector embedding input validated

### External APIs
- API keys not hardcoded
- Rate limiting implemented
- Error messages safe
- HTTPS enforced

## Zen Delegation

Use `mcp_zen_secaudit` for comprehensive security analysis:

```javascript
mcp_zen_secaudit({
  step: "Security audit of changes",
  step_number: 1,
  total_steps: 2,
  next_step_required: true,
  findings: "Analyzing security implications...",
  relevant_files: [
    "/Users/ciaastek/Projects/Sirocco/10x-mapmaster/supabase/migrations/000001_initial_schema.sql",
    "/Users/ciaastek/Projects/Sirocco/10x-mapmaster/src/stores/auth.ts"
  ],
  audit_focus: "comprehensive",
  threat_level: "high",
  security_scope: "RLS policies, authentication, input validation",
  model: "gemini-2.5-pro"
})
```

## Severity Levels

**CRITICAL**: RLS disabled, auth bypass, SQL injection, hardcoded secrets
**HIGH**: Missing validation, XSS, data exposure, missing rate limiting
**MEDIUM**: Suboptimal RLS, performance issues
**LOW**: Code quality, documentation gaps

## Production Safety

**NEVER on production:**
- ❌ Disable RLS
- ❌ Drop tables
- ❌ DELETE without WHERE
- ❌ Modify auth without backup

**ALWAYS:**
- ✅ Test locally first (`npx supabase db reset`)
- ✅ Non-destructive changes only
- ✅ Feature flags for risky changes

## Dependency Scan

```bash
npm audit  # Fix critical/high immediately
```
