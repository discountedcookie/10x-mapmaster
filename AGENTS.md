# 10x-Mapmaster

**Geographic guessing game with semantic embeddings and learning.**

## Architecture

**Database-first.** ALL business logic lives in PostgreSQL. Frontend is presentation only.

Read `.opencode/rules/architecture.md` for detailed constraints.

## Agent Behavior

Behavior, honesty, and session-context rules are defined in `.opencode/rules/behavior.md`. All agents must follow those rules.

## Key Directories

```
src/                    # Vue 3 frontend (presentation only)
supabase/db/            # Database source files (ALL business logic)
supabase/functions/     # Edge functions (LLM, embeddings)
openspec/               # Specifications and change proposals
.opencode/skills/       # Workflow skills (load when relevant)
```

## Skills System

This project uses skills for workflow automation. Skills are in `.opencode/skills/`.

**Load relevant skills based on your task:**

| Task                           | Load Skill                            |
| ------------------------------ | ------------------------------------- |
| New feature or behavior change | `openspec-check` → `openspec-propose` |
| Implementing approved change   | `openspec-apply` + `test-tdd`         |
| Bug or test failure            | `systematic-debugging`                |
| After implementation           | `code-review`                         |
| Working with subagents         | `subagent-workflow`                   |
| Vague or complex request       | `brainstorming`                       |

Skills auto-load based on their descriptions. Check `using-skills` skill if unsure.

## Session Start

1. Check `openspec list` for active changes
2. Check `openspec list --specs` for existing capabilities
3. Load relevant skills based on task type

## Subagents

Before invoking subagents, load the `subagent-workflow` skill.

Key points:

- Track session_ids for recalls
- Scope tasks specifically
- Verify output before proceeding

## Rules (Always-On)

| Rule                              | Purpose                        |
| --------------------------------- | ------------------------------ |
| `.opencode/rules/architecture.md` | Database-first constraints     |
| `.opencode/rules/core.md`         | Baseline rules                 |
| `.opencode/rules/behavior.md`     | Honesty + context + discipline |
