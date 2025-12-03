# 10x-Mapmaster

**Geographic guessing game with semantic embeddings and learning.**

## Architecture

**Database-first.** ALL business logic lives in PostgreSQL. Frontend is presentation only.

```
src/                    # Vue 3 frontend (presentation only)
supabase/db/            # Database source files (ALL business logic)
supabase/functions/     # Edge functions (LLM, embeddings)
openspec/               # Specifications and change proposals
.opencode/skills/       # Workflow skills (load when relevant)
```

## Tool Usage

You have dedicated tools for file operations. Use them:

| Task                  | Tool   | NOT bash             |
| --------------------- | ------ | -------------------- |
| Read file contents    | `Read` | ~~cat, head, tail~~  |
| List directory        | `List` | ~~ls, find -type d~~ |
| Find files by pattern | `Glob` | ~~find, ls~~         |
| Search file contents  | `Grep` | ~~grep, rg~~         |

Bash commands `cat`, `ls`, `find`, `grep` are DENIED and will fail.

Bash is permitted ONLY for: `bun run`, `supabase`, `psql`, `git`, `openspec`, and output filtering (`head`, `tail`, `wc` when piping).

## Honesty Policy

- Never invent facts. Say "I don't know" when uncertain.
- Never claim success without evidence. Verify with tool output.
- Never hide errors. Surface them immediately.
- Correct yourself immediately if you realize a mistake.
- Distinguish between "verified" and "assumed" information.

## Task Discipline

- Complete current task before starting new ones.
- Mark todos done immediately after completion, not in batches.
- If blocked, say why and propose alternatives.

## Skills

Skills are available as tools. Each skill has a description explaining when to use it. Load skills when their description matches your situation - they contain proven workflows that help you work systematically.

## Session Start

1. Check `openspec list` for active changes
2. Check `openspec list --specs` for existing capabilities

## Subagents

When dispatching work to subagents, load `subagent-workflow` first. It covers session management, task scoping, and output verification.
