<!-- OPENSPEC:START -->

# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# 10x-Mapmaster

**Geographic guessing game with semantic embeddings and learning.**

## Architecture

**Database-first.** ALL business logic lives in PostgreSQL. Frontend is presentation only.

See `.opencode/rules/architecture.md` for detailed constraints.

## Key Directories

```
src/                    # Vue 3 frontend (presentation only)
supabase/db/            # Database source files (ALL business logic)
supabase/functions/     # Edge functions (LLM, embeddings)
openspec/               # Specifications and change proposals
```

## Before Invoking Subagents

Read `.opencode/rules/subagents.md` to understand:

- What each subagent knows and doesn't know
- What tools it has access to
- How to scope tasks effectively

## Session Start

1. Check `openspec list` for active changes
2. Check `openspec list --specs` for existing capabilities
3. If task relates to a spec, read it first

## External File Loading

When you encounter a file reference (e.g., `@.opencode/rules/architecture.md`), use the Read tool to load it on a need-to-know basis.

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Rule References

| When                               | Load                             |
| ---------------------------------- | -------------------------------- |
| Implementing features, fixing bugs | @.opencode/rules/architecture.md |
| Before invoking any subagent       | @.opencode/rules/subagents.md    |
| Planning or proposals              | @openspec/AGENTS.md              |
