# Frontend Rules

This is a **presentation-only** layer. NO game logic here.

## Violations to Flag

If you see any of these in `src/`, flag as architectural violation:

- Scoring calculations or confidence math
- Game state transitions (win/lose logic)
- Candidate filtering or ranking
- Direct database writes (except via `supabase.rpc()`)

## Patterns to Follow

- **Composables** for shared reactive logic (`src/composables/`)
- **Pinia stores** for global state (`src/stores/`)
- **shadcn-vue** for UI components
- **vue-i18n** with ICU MessageFormat for translations

## Type Safety

- No `any` - use proper types from `src/types/`
- Explicit return types on exported functions
- Non-null assertions (`!`) require prior type narrowing

## Data Access

All data flows through:

```typescript
supabase.rpc('function_name', params) // Game actions
supabase.from('view_name').select() // Read-only views
```

Never access tables directly. Views and RPCs only.
