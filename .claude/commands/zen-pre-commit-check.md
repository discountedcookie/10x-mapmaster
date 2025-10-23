# Pre-Commit Check

Fast automated quality and security check before every commit.

## Quality Gates (BLOCKING)

```bash
npm run lint         # Auto-fix formatting
npm run type-check   # TypeScript validation
npm test:unit        # Unit tests must pass
```

## Security Scan (WARNING)

Use `mcp_zen_precommit` for security analysis:

```javascript
mcp_zen_precommit({
  step: "Pre-commit security and quality analysis",
  step_number: 1,
  total_steps: 1,
  next_step_required: false,
  findings: "Analyzing staged changes for security issues...",
  path: "/Users/ciaastek/Projects/Sirocco/10x-mapmaster",
  include_staged: true,
  include_unstaged: false,
  precommit_type: "external",
  model: "gemini-2.5-pro"
})
```

## Security Hotspots

- Hardcoded secrets or API keys
- TypeScript `any` types (BLOCKING)
- SQL injection vulnerabilities
- XSS in user input
- Weak RLS policies
- Debug `console.log` statements

## Commit Message Format

Use Conventional Commits:
```
<type>(scope): description

Types: feat, fix, refactor, test, docs, chore, perf, security
```

Example:
```
feat(game): add confidence score to result card
```

See `.github/commit_template.md` for more examples.
