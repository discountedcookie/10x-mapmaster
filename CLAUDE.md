# 10x-mapmaster Development Guide

## ⚡ TL;DR (Returning Agents)

- **Tech**: Vue 3 + Supabase + pgvector + MapLibre
- **Pattern**: PostgREST (DB does work), Session-first architecture
- **File Reads**: Serena overview → symbols only (NEVER full files)
- **DB Ops**: Supabase MCP only (never direct supabase CLI)
- **Testing**: `npm test && npm test:db && npm run type-check`
- **Production DB**: LIVE - NO resets, NO destructive operations
- **Workflow**: Feature branches + agentic reviews before merge

## 🚀 START HERE

**Before any task:**
1. Read `AGENTS.md` for product vision
2. Check Serena memories: `project-setup-and-current-state`, `mvp-task-breakdown-simple`
3. Use MCP servers: Context7 (docs), Serena (code), Playwright (testing)

**After completing:**
1. Update `project-setup-and-current-state` (overwrite outdated)
2. Run `npm test` and `npm run lint`
3. Document in `design-decisions-log` or `known-issues-and-gotchas` if significant

## 🎯 Routing Decision Tree

### Local Agent Handles (Default)
- Initial triage & planning (task decomposition)
- File system operations (read, write, list)
- Code inspection with Serena (`get_symbols_overview`, `find_symbol`)
- Simple code generation (boilerplate, small modifications)
- Running safe local commands (`npm test`, `npm run lint`, `npx supabase db reset`)
- Documentation updates

### Delegate to Zen MCP
**Triggers:**
- **Complex Analysis/Design**: Architectural decisions, design patterns, system-wide refactoring
  - Action: Use `.claude/commands/generate_feature_plan` or `mcp_zen_analyze`
- **Security-Sensitive Operations**: Auth, RLS policies, migrations touching security
  - Action: Use `.claude/commands/analyze_security_impact`
- **Database Schema Changes**: New migrations, complex query optimization
  - Action: Use `.claude/commands/generate_db_migration`
- **Agentic Code Review**: Pre-commit checks, PR reviews
  - Action: Use `.claude/commands/pre_commit_check` or `.claude/commands/review_code_changes`
- **Complex Refactoring**: Multi-file changes, algorithm optimization
  - Action: Use `.claude/commands/refactor_component`

### Ask User First
- Production database operations (user runs seed scripts)
- Deployment to production
- Breaking changes to public API
- Unclear requirements or ambiguous specifications

## 💡 Core Principles

**Tech Stack:** Vue 3 Composition API + TypeScript + Supabase + pgvector + MapLibre
**Data Pattern:** PostgREST (DB does work, frontend filters)
**Vector System:** `vector(384)` with gte-small, cached embeddings
**File Structure:** `src/{components,composables,stores,lib,types,views}`

**Non-Negotiables:**
- RLS policies always
- Migrations only (never manual schema)
- No `any` types
- Async/await pattern

## ⚡ Serena: NEVER Read Entire Files!

**The Pattern:** Overview → Symbol → References → Edit

```typescript
// 1. Get overview
mcp__serena__get_symbols_overview("src/components/map/MapView.vue")

// 2. Read specific symbol
mcp__serena__find_symbol({
  name_path: "MapView/setupMap",
  relative_path: "src/components/map/MapView.vue",
  include_body: true  // Only when editing
})

// 3. Check references before changing
mcp__serena__find_referencing_symbols({
  name_path: "fetchQuestions",
  relative_path: "src/composables/useQuestions.ts"
})

// 4. Edit precisely
mcp__serena__replace_symbol_body({
  name_path: "MapView/updateMarkers",
  relative_path: "src/components/map/MapView.vue",
  body: `const updateMarkers = async () => { /* impl */ }`
})
```

**Key Tools:**
- `get_symbols_overview` - File structure
- `find_symbol` - Specific code (use `substring_matching: true`, `relative_path`, LSP kinds)
- `find_referencing_symbols` - Impact analysis
- `search_for_pattern` - Non-code (TODOs, configs)
- `insert_before_symbol` / `insert_after_symbol` - Add code
- `think_about_collected_information` - After research
- `think_about_task_adherence` - Before editing

**Memories:**
- `project-setup-and-current-state` (OVERWRITE)
- `design-decisions-log` (APPEND)
- `known-issues-and-gotchas` (APPEND)

## 🧠 Memory Index (Serena)

**Always read:**
- `project-setup-and-current-state` - Current architecture & status

**Read if relevant:**
- `design-decisions-log` - Architectural choices & rationale
- `known-issues-and-gotchas` - Pitfalls to avoid
- `successful-workflow-patterns-oct22` - Proven patterns

**Update after completion:**
- `design-decisions-log` (append) - If architectural decision made
- `known-issues-and-gotchas` (append) - If pitfall discovered
- `project-setup-and-current-state` (overwrite) - If schema/config changed

## 🔄 Workflow Commands

Use `.claude/commands/*.md` prompts for Zen MCP delegation:

- `generate_feature_plan` - Complex feature planning
- `pre_commit_check` - Pre-commit quality gates
- `review_code_changes` - Full PR code review
- `analyze_security_impact` - Security-focused review
- `generate_db_migration` - Safe migration generation
- `refactor_component` - Component optimization

Run with: `/command-name` in Cursor

## 🚨 Critical Safety Rules

**NEVER Run These Commands:**
- ❌ `npm run seed:places` - Requires env variables, user-only
- ❌ `npm run seed:questions` - Requires env variables, user-only
- ❌ `supabase db reset --remote` - Production database, user-only
- ❌ Any script that needs API keys or env variables

**ALWAYS Run These Commands:**
- ✅ `npx supabase db reset` - Local database reset (safe)
- ✅ `npm test:unit` - Unit tests
- ✅ `npm test:db` - Database tests
- ✅ `npm run lint` - Linter

**Database Operations:**
- ✅ Use Supabase MCP (`mcp_supabase_execute_sql`) for queries
- ✅ Use Supabase MCP (`mcp_supabase_apply_migration`) for schema changes
- ❌ Never `supabase db push` without user approval

**Seeding Workflow:**
1. Agent resets local DB: `npx supabase db reset`
2. Agent asks user to run: `npm run seed:places && npm run seed:questions`
3. Agent verifies with Supabase MCP queries

## 🗂️ Database & Embeddings

**Migrations (in order):**
1. `000001_initial_schema.sql` - Schema, extensions, RLS, triggers
2. `000002_seed_data.sql` - Places (names only) + Questions (with types/regions)
3. `000003_database_functions.sql` - Search/filter functions

**Daily:** `npx supabase db reset`
**After reset (to enrich seed data):**
1. Run `npm run seed:places` - Enriches places via Nominatim/APIs + generates embeddings
2. Run `npm run seed:questions` - Generates embeddings for semantic questions

**When updating seed data:**
1. Edit `000002_seed_data.sql` (places: names only; questions: text + type + region)
2. Reset database and run seed scripts

**Why:** Places start with just names (like user input), enrichment via scripts mirrors production flow

## 🌍 External Integrations

**Nominatim:** 1 req/sec, dedupe by coordinates ±0.001°
**MapLibre:** Lazy load, cluster markers, real-time candidate updates

## ✅ Testing

Playwright (E2E) + Vitest (unit) + Manual QA + RLS policy testing in Supabase dashboard
