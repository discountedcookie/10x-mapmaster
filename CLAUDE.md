# 10x-mapmaster Development Guide

## 🚀 START HERE

**Before any task:**
1. Read `AGENTS.md` for product vision
2. Check Serena memories: `project-setup-and-current-state`, `mvp-task-breakdown-simple`
3. Use MCP servers: Context7 (docs), Serena (code), Playwright (testing)

**After completing:**
1. Update `project-setup-and-current-state` (overwrite outdated)
2. Run `npm test` and `npm run lint`
3. Document in `design-decisions-log` or `known-issues-and-gotchas` if significant

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
