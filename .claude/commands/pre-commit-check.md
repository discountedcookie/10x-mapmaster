# Pre-Commit Check (Local)

Fast automated quality checks before every commit.

## Quality Gates (BLOCKING)

Run these commands locally before committing:

```bash
npm run lint         # Auto-fix formatting
npm run type-check   # TypeScript validation
npm test:unit        # Unit tests must pass
```

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
