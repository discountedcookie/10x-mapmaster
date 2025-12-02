---
name: using-skills
description: >-
  Load at session start or when unsure which skill applies. Explains available
  skills and when to use each. Check this to understand the skill system.
---

# Using Skills

Skills are composable workflows that guide your behavior for specific tasks.

> **Announce:** "I'm checking available skills to determine the right approach."

## Skill Categories

### Planning Skills (Interactive - ASK User)

Load these when you need to clarify, design, or get approval BEFORE implementation.

| Skill | When to Load |
|-------|--------------|
| `brainstorming` | Request is vague, complex, or needs design exploration |
| `openspec-check` | Before ANY implementation - check if specs exist |
| `openspec-propose` | New feature, behavioral change, or architecture modification |
| `task-planning` | Breaking approved work into implementable tasks |

**Key behavior:** These skills ASK questions and WAIT for approval.

### Execution Skills (Strict - FOLLOW Plan)

Load these when you have approved work to implement.

| Skill | When to Load |
|-------|--------------|
| `openspec-apply` | Implementing an approved OpenSpec change |
| `test-tdd` | Writing ANY code (test first, always) |
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

## How Skills Chain

Skills reference each other with `REQUIRED SUB-SKILL:` markers.

Example flow:
1. User asks for feature → load `openspec-check`
2. No spec exists → `openspec-check` says load `openspec-propose`
3. Proposal approved → load `task-planning`
4. Tasks ready → load `openspec-apply` + `test-tdd`
5. Implementation done → load `code-review`

## Iron Law

```
ANNOUNCE WHICH SKILL YOU'RE USING BEFORE STARTING
```

Format: "I'm using [skill] to [what you're doing]."

## Selecting Skills

Ask yourself:
1. Am I planning or executing? → Planning skills ask, execution skills follow
2. Is this a new feature or existing behavior? → New = check specs first
3. Am I writing code? → Always load `test-tdd`
4. Am I investigating or fixing? → Investigate first, then fix

When in doubt, load `openspec-check` first - it will guide you to the right path.
