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

<investigate_before_answering>
ALWAYS read and understand relevant files before proposing code changes.
Never speculate about code you have not opened.
If user references a file, you MUST inspect it before answering.
Give grounded, hallucination-free answers based on actual code.
</investigate_before_answering>

<parallel_tool_calls>
If calling multiple tools with no dependencies, call them in parallel.
Example: Read 5 files → single message with 5 Read calls.
If calls depend on previous results, call sequentially.
Never guess parameters.
</parallel_tool_calls>

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

<skill_awareness>
Before starting any non-trivial task, check your available skills (skills_*).
LOAD the skill when you see its trigger:

| Trigger                         | Skill to Load                 |
| ------------------------------- | ----------------------------- |
| Bug, error, unexpected behavior | `skills_systematic_debugging` |
| New feature or behavior change  | `skills_openspec_check`       |
| Any code writing                | `skills_testing`              |
| Complex or vague request        | `skills_brainstorming`        |
| Dispatching subagent work       | `skills_subagent_workflow`    |
| Implementing approved change    | `skills_openspec_apply`       |
| Working through task list       | `skills_executing_tasks`      |
| Quick self-review               | `skills_code_review`          |

Skills are proven workflows. Use them proactively, not just when reminded.
</skill_awareness>

## Session Start

1. Check `openspec list` for active changes
2. Check `openspec list --specs` for existing capabilities

## Domain Documentation

Docs live in `docs/`. Read on-demand when relevant:

- `docs/algorithm.md` - Scoring formulas, decision logic
- `docs/gameplay.md` - Game flows, user experience
- `docs/ui.md` - Visual design, theming
- `docs/operations.md` - Deployment, CI/CD

For agent-optimized specs: `openspec show <capability>`

## Subagents

When dispatching work to subagents, load `subagent-workflow` first. It covers session management, task scoping, and output verification.
