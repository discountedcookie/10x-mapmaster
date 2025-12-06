# Skill-Pattern Map

Maps code locations to skills that document them.

## Database Skills

| Code Path | Skill | What It Documents |
|-----------|-------|-------------------|
| `supabase/db/game_logic/functions/` | `game-scoring` | Confidence calculation, softmax, ranking |
| `supabase/db/game_logic/functions/*embedding*` | `postgres-vectors` | Vector operations, similarity |
| `supabase/db/game_logic/functions/*geographic*` | `postgis-spatial` | Spatial queries, ST_* functions |
| `supabase/db/public/functions/` | `database-first` | RPC patterns, SECURITY DEFINER |
| `supabase/db/schema/` | `codebase-conventions` | Table structure, enums, constraints |

## Frontend Skills

| Code Path | Skill | What It Documents |
|-----------|-------|-------------------|
| `src/composables/map/useMapCamera.ts` | `maplibre-camera` | Camera control, animations |
| `src/composables/map/useGlobeVisibility.ts` | `maplibre-camera` | Globe visibility filtering |
| `src/composables/map/useCinematicIntro.ts` | `maplibre-camera` | Custom animations |
| `src/components/map/*Layer.vue` | `maplibre-layers` | Layer components, GeoJSON |
| `src/stores/mapLayers.ts` | `maplibre-layers` | Layer registration pattern |
| `src/composables/*.ts` | `vue-composables` | Composable patterns |
| `src/stores/*.ts` | `vue-composables` | Pinia store patterns |
| `src/lib/api/` | `database-first` | RPC calling patterns |
| `src/lib/errors.ts` | `vue-composables` | Error handling, withLoadingState |
| `src/components/ui/` | `shadcn-vue` | UI component usage |

## Edge Function Skills

| Code Path | Skill | What It Documents |
|-----------|-------|-------------------|
| `supabase/functions/*/index.ts` | `edge-functions` | Deno handler patterns |
| `supabase/functions/call-llm/` | `edge-functions` | LLM integration |
| `supabase/functions/types/` | `edge-functions` | Zod schemas |

## Meta Skills

| Trigger | Skill | Purpose |
|---------|-------|---------|
| Architecture question | `database-first` | Where code belongs |
| Naming question | `codebase-conventions` | Standards |
| After refactor | `knowledge-sync` | Update skills |
| New feature | `openspec-check` | Check specs first |

## Updating This Map

When adding new skills or major code reorganization:
1. Update this map
2. Update `.opencode/glossary.md`
3. Update `using-skills` skill
