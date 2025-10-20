# 10x-mapmaster Development Guide

## START HERE

**Before any task:**

1. **Read AGENTS.md** for product vision and architecture
2. **Check Serena memories:**
   ```
   mcp__serena__list_memories
   mcp__serena__read_memory project-setup-and-current-state
   mcp__serena__read_memory mvp-task-breakdown-simple
   ```
3. **Use MCP servers** (see below)

**After completing a task:**

1. **Update Serena:** `project-setup-and-current-state` (overwrite outdated sections)
2. **Run tests:** `npm test` and `npm run lint`
3. **Optionally document:**
   - `design-decisions-log` (append, keep history) - significant architectural choices
   - `known-issues-and-gotchas` (append) - problems + solutions

## MCP Servers

Use these tools before searching externally:

- **Context7**: API docs (Vue, Supabase, TypeScript, MapLibre, pgvector)
- **Serena**: Code analysis, find symbols, research patterns (project activated)
- **Playwright**: E2E testing, UI verification

## Development Standards

### Vue 3 + TypeScript
- Composition API only (`<script setup lang="ts">`)
- No `any`, prefer interfaces
- Composables prefixed with `use`
- Typed props and emits

### Supabase
- Always use RLS policies
- Migrations only (no manual schema changes)
- UUIDs for primary keys
- Include `created_at` and `updated_at`

### Vector Embeddings (Full System)
- Store as `vector(384)` (gte-small)
- Use cosine similarity (pgvector)
- Cache embeddings to avoid redundant calls

### Code Style
- Meaningful variable names
- Async/await over promise chains
- Early returns
- Comments explain "why" not "what"

### File Organization
```
src/
  components/
    game/        # Game-specific
    map/         # Map-related
    ui/          # shadcn-vue
  composables/   # Shared logic (use*)
  stores/        # Pinia
  lib/           # Utilities
  types/         # TypeScript interfaces
  views/         # Pages
```

## Current Implementation

**Check Serena memory `project-setup-and-current-state` for:**
- What's implemented
- Current MVP scope vs full system
- Files created
- Next steps

## Serena Workflow

### Memory Types
- **project-setup-and-current-state**: Current status (OVERWRITE outdated info)
- **mvp-task-breakdown-simple**: Task plan (UPDATE as scope changes)
- **design-decisions-log**: Architectural choices (APPEND with dates)
- **known-issues-and-gotchas**: Problems + solutions (APPEND, never delete)

### Commands
```typescript
mcp__serena__list_memories
mcp__serena__read_memory { memory_file_name: "name.md" }
mcp__serena__write_memory { memory_name: "name", content: "..." }
```

## Common Patterns

### PostgREST + Supabase
All data operations via database queries, not application logic. Example: questions fetched from DB, filtering applied in frontend based on `filter_type`.

### Nominatim Integration
- Rate limit: 1 req/sec (debounce inputs)
- Check for duplicates (coordinates ±0.001°)
- Save descriptors as JSONB

### Map Integration
- Lazy load markers
- Cluster when zoomed out
- Update candidates in real-time during game

## Testing
- Playwright for E2E (existing: `e2e/home.spec.ts`)
- Vitest for unit tests
- Manual QA for map interactions
- Test RLS policies in Supabase dashboard

## Key Constraints
- Never bypass RLS in frontend
- Respect Nominatim rate limits
- Use migrations for all schema changes
- Handle loading/error states
- User-friendly error messages (no stack traces)
