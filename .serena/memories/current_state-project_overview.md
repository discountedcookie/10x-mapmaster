# 10x-mapmaster - Current Project State

## Overview
Intelligent geography guessing game where players describe a place, and the system uses vector embeddings to ask strategic yes/no questions to identify it. The game learns from every session, improving matching accuracy.

## Current Status: ✅ ALGORITHMIC FILTERING COMPLETE

**Latest Milestone:** Pure algorithmic filtering implemented - all hardcoded logic removed
**Completion Date:** October 23, 2025

### Recent Changes (October 23, 2025)

**Algorithmic Filtering Refactor** - COMPLETED ✅
- Removed 40+ lines of hardcoded CASE WHEN statements
- Implemented pure pgvector + PostGIS filtering
- Geographic questions now visible (0.6 baseline score)
- Test results: 2 questions to solve Machu Picchu (15→2 candidates)
- Adding questions now requires INSERT only (no code changes)

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

**Agent Commands** (`.claude/commands/*.md`):
- `generate_feature_plan` - Complex feature planning with Zen
- `pre_commit_check` - Pre-commit quality gates (BLOCKING)
- `review_code_changes` - Full PR code review
- `analyze_security_impact` - Security review for RLS/auth changes (BLOCKING)
- `generate_db_migration` - Safe migration generation
- `refactor_component` - Component optimization

**Routing Decision Tree**:
- **Local Agent**: File ops, simple edits, safe commands, Serena/Supabase MCP
- **Zen MCP**: Complex analysis, security, DB migrations, code reviews, refactoring
- **Ask User**: Production DB ops, deployment, breaking changes

**Quality Gates**:
- Commit: lint + type-check + unit tests (BLOCKING)
- PR: + db tests + E2E + full review + security (if schema/auth changed)
- DB changes: Migration safety + destructive analysis (BLOCKING)
- Security changes: RLS policy review + auth logic review (BLOCKING)

### Production Safety

**NEVER on production**:
- ❌ `supabase db reset --remote`
- ❌ `npm run seed:places` / `npm run seed:questions` (require env vars)
- ❌ Destructive operations (DROP, TRUNCATE, DELETE without WHERE)

**ALWAYS**:
- ✅ Feature branches for all work
- ✅ Local DB reset: `npx supabase db reset` (SAFE)
- ✅ Non-destructive migrations only
- ✅ RLS enabled on all tables
- ✅ Security review for schema/auth changes

## Architecture Summary

**Core Filtering (October 23, 2025):**
1. **Phase 1:** Initial candidates via pgvector similarity (top 20)
2. **Phase 2:** Geographic filtering via PostGIS bbox intersection
3. **Phase 3:** Semantic adjustment via pgvector question similarity
4. **Phase 4:** Spatial confidence via cluster analysis

**Key Principle:** No hardcoded business logic - only pgvector + PostGIS operations

## Next Planned Improvements

### Phase 2: Rich Embeddings (Optional - 4 hours)
- Add location context: "Eiffel Tower in Paris, capital of France"
- Add materials, age, function to embedding text
- Result: Better semantic matching without field checks

### Phase 3: Question Embeddings (Optional - 2 hours)
- Generate embeddings for geographic questions
- "Is it in Europe?" → "European architecture, cities, culture"
- Enable semantic + spatial matching for all questions
