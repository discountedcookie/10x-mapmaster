### AI Agent Workflow System (October 22, 2025)

**Core Workflow**: Production DB is LIVE - all development on feature branches with agentic reviews

**Feature Branch Workflow**:
1. Create branch: `git checkout -b feature/<name>`
2. Develop locally (safe to reset local DB: `npx supabase db reset`)
3. Pre-commit check: `/pre_commit_check` (lint, types, tests, security)
4. Commit with Conventional Commits: `feat(scope): description`
5. Push and create PR
6. PR review: `/review_code_changes` (comprehensive analysis)
7. Merge after approval

**Cursor Commands** (`.claude/commands/*.md`):
- `generate_feature_plan` - Complex feature planning with Zen
- `pre_commit_check` - Pre-commit quality gates (BLOCKING)
- `review_code_changes` - Full PR code review
- `analyze_security_impact` - Security review for RLS/auth changes (BLOCKING)
- `generate_db_migration` - Safe migration generation
- `refactor_component` - Component optimization
- `zen-supervisor` - Zen MCP delegation guide

**Routing Decision Tree**:
- **Local Agent**: File ops, simple edits, safe commands, Serena/Supabase MCP
- **Zen MCP**: Complex analysis, security, DB migrations, code reviews, refactoring
- **Ask User**: Production DB ops, deployment, breaking changes

**Quality Gates**:
- Commit: lint + type-check + unit tests (BLOCKING)
- PR: + db tests + E2E + full review + security (if schema/auth changed)
- DB changes: Migration safety + destructive analysis (BLOCKING)
- Security changes: RLS policy review + auth logic review (BLOCKING)
