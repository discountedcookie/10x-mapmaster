---
name: using-skills
description: >-
  Load at session start or when unsure which skill applies. Explains available
  skills and when to use each. Check this to understand the skill system.
---

# Using Skills

Skills are composable workflows that guide your behavior for specific tasks.

> **Announce:** "I'm checking available skills to determine the right approach."

## Quick Reference

| Trigger | Skill to Load |
|---------|---------------|
| Bug, error, unexpected behavior | `systematic-debugging` |
| New feature or behavior change | `openspec-check` |
| Any code writing | `testing` |
| Complex or vague request | `brainstorming` |
| Dispatching subagent work | `subagent-workflow` |
| Implementing approved change | `openspec-apply` |
| Working through task list | `executing-tasks` |
| Quick self-review | `code-review` |
| Improve agent config | `config-tuning` |

## Skill Categories

### Planning Skills (Interactive - ASK User)

Load these when you need to clarify, design, or get approval BEFORE implementation.

| Skill | When to Load |
|-------|--------------|
| `brainstorming` | Request is vague, complex, or needs design exploration |
| `openspec-check` | Before ANY implementation - check if specs exist |
| `openspec-propose` | New feature, behavioral change, or architecture modification |
| `task-planning` | Breaking approved work into implementable tasks |
| `config-tuning` | User notices a pattern that should be in config |

**Key behavior:** These skills ASK questions and WAIT for approval.

### Execution Skills (Strict - FOLLOW Plan)

Load these when you have approved work to implement.

| Skill | When to Load |
|-------|--------------|
| `openspec-apply` | Implementing an approved OpenSpec change |
| `testing` | Writing ANY code (test first, always) |
| `executing-tasks` | Working through a task checklist |

**Key behavior:** These skills FOLLOW the plan exactly. No deviations.

### Investigation Skills (Gather Info - REPORT)

Load these when you need to understand something before acting.

| Skill | When to Load |
|-------|--------------|
| `systematic-debugging` | Bug, test failure, unexpected behavior |
| `code-review` | After implementation, before commit |

**Key behavior:** These skills INVESTIGATE and REPORT. They don't fix.

### Workflow Skills

Load these for orchestration patterns.

| Skill | When to Load |
|-------|--------------|
| `subagent-workflow` | Dispatching or recalling subagents |
| `knowledge-sync` | After major refactors, update skills with new patterns |

## Domain Skills

Load these for project-specific patterns. They provide code examples and anti-patterns.

### Foundation

| Skill | When to Load |
|-------|--------------|
| `database-first` | ANY database work - iron law: all logic in PostgreSQL |
| `codebase-conventions` | File structure, naming, constraints |

### Database

| Skill | When to Load |
|-------|--------------|
| `postgres-vectors` | Embeddings, similarity search, pgvector operators |
| `postgis-spatial` | Geographic queries, ST_* functions, regions |
| `game-scoring` | Candidate scoring, confidence, softmax aggregation |
| `trait-learning` | Trait extraction, learning loop, LLM prompts |

### Frontend

| Skill | When to Load |
|-------|--------------|
| `vue-composables` | useX patterns, Pinia stores, withLoadingState |
| `maplibre-camera` | Camera movements, flyTo, animations |
| `maplibre-layers` | GeoJSON sources, layer styling, events |
| `shadcn-vue` | UI components, forms, dialogs |

### Edge Functions

| Skill | When to Load |
|-------|--------------|
| `edge-functions` | Deno patterns, LLM calls, embeddings |

### Testing

| Skill | When to Load |
|-------|--------------|
| `gameplay-sql` | Test game via database tools (game_start, game_turn) |
| `gameplay-browser` | Test game via browser with Chrome DevTools |

## How Skills Chain

Skills reference each other with `REQUIRED SUB-SKILL:` markers.

Example flow:
1. User asks for feature -> load `openspec-check`
2. No spec exists -> `openspec-check` says load `openspec-propose`
3. Proposal approved -> load `task-planning`
4. Tasks ready -> load `openspec-apply` + `testing`
5. Implementation done -> load `code-review`

## Iron Law

```
ANNOUNCE WHICH SKILL YOU'RE USING BEFORE STARTING
```

Format: "I'm using [skill] to [what you're doing]."

## Selecting Skills

Ask yourself:
1. Am I planning or executing? -> Planning skills ask, execution skills follow
2. Is this a new feature or existing behavior? -> New = check specs first
3. Am I writing code? -> Always load `testing`
4. Am I investigating or fixing? -> Investigate first, then fix
5. Does this involve database/frontend/edge? -> Load domain skill

When in doubt, load `openspec-check` first - it will guide you to the right path.

## Domain Skill Selection Guide

| Task | Primary Skill | Also Consider |
|------|--------------|---------------|
| Vector similarity query | `postgres-vectors` | `game-scoring` |
| Geographic filtering | `postgis-spatial` | |
| Candidate ranking | `game-scoring` | `postgres-vectors` |
| New trait extraction | `trait-learning` | `edge-functions` |
| Map camera animation | `maplibre-camera` | |
| Map markers/layers | `maplibre-layers` | |
| Vue reactive state | `vue-composables` | |
| Pinia store | `vue-composables` | `database-first` |
| UI component | `shadcn-vue` | |
| LLM integration | `edge-functions` | `trait-learning` |
| Manual game testing | `gameplay-sql` | `gameplay-browser` |
