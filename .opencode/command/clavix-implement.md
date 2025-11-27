---
description: Execute tasks from the implementation plan
---

# Clavix Implement - AI-Assisted Task Execution

You are helping the user implement tasks from their task plan with AI assistance.

---

## CLAVIX MODE: Implementation

**You are in Clavix implementation mode. You ARE authorized to write code and implement features.**

**YOUR ROLE:**
- ✓ Read and understand task requirements
- ✓ Implement tasks from tasks.md
- ✓ Write production-quality code
- ✓ Follow PRD specifications
- ✓ Run `clavix task-complete` after each task

**IMPLEMENTATION AUTHORIZED:**
- ✓ Writing functions, classes, and components
- ✓ Creating new files and modifying existing ones
- ✓ Implementing features described in tasks.md
- ✓ Writing tests for implemented code

**MODE ENTRY VALIDATION:**
Before implementing, verify:
1. Source documents exist (tasks.md in .clavix/outputs/)
2. Output assertion: "Entering IMPLEMENTATION mode. I will implement tasks from tasks.md."

For complete mode documentation, see: `.clavix/instructions/core/clavix-mode.md`

---

## Instructions

1. **First-time setup - Run CLI command with optional git strategy**:

   Check if `.clavix-implement-config.json` exists in the PRD output folder.

   **If config file does NOT exist** (first time running implement):

   a. **Check if user wants git auto-commits** (optional, only if tasks.md has >3 phases):
      ```
      "I notice this implementation has [X] phases with [Y] tasks total.

      Would you like me to create git commits automatically as I complete tasks?

      Options:
      - per-task: Commit after each task (frequent commits, detailed history)
      - per-5-tasks: Commit every 5 tasks (balanced approach)
      - per-phase: Commit when each phase completes (milestone commits)
      - none: Manual git workflow (I won't create commits)

      Please choose one, or I'll proceed with 'none' (manual commits)."
      ```

   b. **Run the CLI command to initialize**:
      ```bash
      # With git strategy (if user specified):
      clavix implement --commit-strategy=per-phase

      # Or without (defaults to 'none' - manual commits):
      clavix implement
      ```

   c. **This will**:
      - Show current progress
      - Display the next incomplete task
      - Create `.clavix-implement-config.json` file
      - Set git auto-commit strategy (or default to 'none')

   d. Wait for command to complete, then proceed with step 2

   **If config file already exists**:
   - Skip to step 2 (implementation loop)

2. **As the AI agent, you should**:

   a. **Read the configuration**:
      - Load `.clavix-implement-config.json` from the PRD folder
      - This contains: commit strategy, current task, and progress stats

   b. **Read the PRD for context**:
      - Open the full PRD to understand requirements
      - Reference specific sections mentioned in tasks

   c. **Read tasks.md**:
      - Find the first incomplete task (marked `- [ ]`)
      - This is your current task to implement

   d. **Implement the task**:
      - Write/modify code as needed
      - Follow quality principles (clarity, structure, actionability)
      - Use PRD requirements as your guide
      - Ask user for clarification if needed

   e. **Complete the task programmatically**:
      - IMPORTANT: NEVER manually edit checkboxes in tasks.md
      - Instead, run: `clavix task-complete {task-id}`
      - The task ID is found in tasks.md (e.g., `phase-1-authentication-1`)
      - This command automatically:
        • Validates the task exists
        • Updates the checkbox in tasks.md
        • Tracks completion in config file
        • Creates git commit (if strategy enabled)
        • Displays the next task
      - Example: `clavix task-complete phase-1-setup-1`

   f. **Move to next task**:
      - The task-complete command shows the next task automatically
      - Read it and repeat the process
      - If you get interrupted, just run `clavix implement` again to resume

3. **Session Resume**:
   - When user runs `clavix implement` again, it automatically picks up from the last incomplete task
   - No manual tracking needed - the checkboxes in tasks.md are the source of truth

## Task Completion Workflow

**CRITICAL: Always use the `clavix task-complete` command**

### Why task-complete is CLI-Only

The `clavix task-complete` command requires:
- State validation across config files
- Atomic checkbox updates in tasks.md
- Conditional git commit execution
- Progress tracking and next-task resolution

Therefore it's implemented as a **CLI command** (not a slash command) and called **automatically by the agent** during implementation workflow.

**Agent Responsibility:** Run `clavix task-complete {task-id}` after implementing each task.
**User Responsibility:** None - agent handles task completion automatically.

### Usage

```bash
# After implementing a task, agent runs:
clavix task-complete {task-id}

# Example
clavix task-complete phase-1-setup-1
```

The command handles:
- Checkbox updates in tasks.md
- Config file tracking
- Git commits (per strategy)
- Progress display
- Next task retrieval

**NEVER manually edit tasks.md checkboxes** - the command ensures proper tracking and prevents state inconsistencies.

## Important Rules

**DO**:
- Read tasks.md to find the current task and its ID
- Implement ONE task at a time
- Use `clavix task-complete {task-id}` after completing each task
- Reference the PRD for detailed requirements
- Ask for clarification when tasks are ambiguous
- Run `clavix implement` again if interrupted to resume

**DON'T**:
- NEVER manually edit checkboxes in tasks.md
- Skip tasks or implement out of order
- Mark tasks complete before actually implementing them
- Assume what code to write - use PRD as source of truth
- Try to track task completion manually

## Task Blocking Protocol

**When a task is blocked** (cannot be completed), follow this protocol:

### Step 1: Detect Blocking Issues

Common blocking scenarios:
- **Missing dependencies**: API keys, credentials, external services not available
- **Unclear requirements**: Task description too vague or conflicts with PRD
- **External blockers**: Need design assets, content, or third-party integration not ready
- **Technical blockers**: Required library incompatible, environment issue, access problem
- **Resource blockers**: Need database, server, or infrastructure not yet set up

### Step 2: Immediate User Communication

**Stop implementation and ask user immediately:**
```
"Task blocked: [Task description]

Blocking issue: [Specific blocker, e.g., 'Missing Stripe API key for payment integration']

Options to proceed:
1. **Provide missing resource** - [What user needs to provide]
2. **Break into sub-tasks** - I can implement [unblocked parts] now and defer [blocked part]
3. **Skip for now** - Mark as [BLOCKED], continue with next task, return later

Which option would you like?"
```

### Step 3: Resolution Strategies

**Option A: User Provides Resource**
- Wait for user to provide (API key, design, clarification)
- Once provided, continue with task implementation

**Option B: Create Sub-Tasks** (preferred when possible)
- Identify what CAN be done without the blocker
- Break task into unblocked sub-tasks
- Example: "Implement payment integration" →
  - [x] Create payment service interface (can do now)
  - [ ] [BLOCKED: Need Stripe API key] Integrate Stripe SDK
  - [ ] Add payment UI components (can do now)
- Implement unblocked sub-tasks, mark blocked ones with [BLOCKED] tag

**Option C: Skip and Mark Blocked**
- Add [BLOCKED] tag to task in tasks.md: `- [ ] [BLOCKED: Missing API key] Task description`
- Note the blocker reason
- Move to next task
- Return to blocked tasks when unblocked

### Step 4: Track Blocked Tasks

**In tasks.md, use [BLOCKED] notation:**
```markdown
## Phase 2: Integration
- [x] Create API client structure
- [ ] [BLOCKED: Waiting for API endpoint spec] Implement data sync
- [ ] Add error handling for API calls
```

**At end of implement session:**
- List all blocked tasks
- Remind user what's needed to unblock each one
- Suggest next steps

### Common Blocking Scenarios & Resolutions

| Blocker Type | Detection | Resolution |
|--------------|-----------|------------|
| Missing API key/credentials | Code requires authentication | Ask user for credentials OR stub with mock for now |
| Vague requirements | Unclear what to implement | Ask specific questions OR propose implementation for approval |
| External dependency | Service/API not available | Create interface/mock OR skip and defer |
| Environment issue | Can't run/test code | Ask user to fix environment OR implement without testing (note risk) |
| Design/content missing | Need specific assets | Create placeholder OR wait for actual assets |

## Example Workflow

**CRITICAL WORKFLOW RULE:**
- Agent implements task → Agent runs `clavix task-complete` → Agent proceeds to next task
- User NEVER manually runs task-complete
- User NEVER manually edits tasks.md checkboxes
- This is an automated workflow, not a manual checklist

```
1. User runs: clavix implement
2. Command shows: "Next task (ID: phase-1-auth-1): Implement user authentication"
3. You (AI agent):
   - Read PRD authentication requirements
   - Implement auth logic
   - Write tests
   - Run: clavix task-complete phase-1-auth-1
   - Command automatically:
     • Marks task complete in tasks.md
     • Updates config tracking
     • Creates git commit (if enabled)
     • Shows next task
   - Continue with next task or wait for user
```

## Finding Task IDs

Task IDs are visible in several places:
1. When you read `tasks.md` - they're in the format `phase-X-name-Y`
2. In the config file (`.clavix-implement-config.json`) under `currentTask.id`
3. When running `clavix implement` - shown next to task description

Example tasks.md structure:
```markdown
## Phase 1: Authentication

- [ ] Implement user registration (ref: User Management)
  Task ID: phase-1-authentication-1

- [ ] Add JWT token generation (ref: User Management)
  Task ID: phase-1-authentication-2
```

To find the task ID programmatically, read tasks.md and look for the pattern `phase-{number}-{sanitized-phase-name}-{counter}`.

## Workflow Navigation

**You are here:** Implement (Task Execution)

**Common workflows:**
- **Full workflow**: `/clavix:plan` → `/clavix:implement` → [execute all tasks] → `/clavix:archive`
- **Resume work**: `/clavix:implement` → Continue from last incomplete task
- **Iterative**: `/clavix:implement` → [complete task] → [pause] → `/clavix:implement` → [continue]

**Related commands:**
- `/clavix:plan` - Generate/regenerate task breakdown (previous step)
- `/clavix:archive` - Archive completed project (final step)
- `/clavix:prd` - Review PRD for context during implementation

## Tips

- The implementation is meant to be iterative and collaborative
- User can pause/resume at any time
- Tasks are designed to be atomic and independently implementable
- Use the PRD as the authoritative source for "what to build"
- Use tasks.md as the guide for "in what order"

---

## Agent Transparency (v4.4)

### Workflow State Detection
## Workflow State Detection

### PRD-to-Implementation States

```
NO_PROJECT → PRD_EXISTS → TASKS_EXIST → IMPLEMENTING → ALL_COMPLETE → ARCHIVED
```

### State Detection Protocol

**Step 1: Check for project config**
```
Read: .clavix/outputs/{project}/.clavix-implement-config.json
```

**Step 2: Interpret state based on conditions**

| Condition | State | Next Action |
|-----------|-------|-------------|
| Config missing, no PRD files | `NO_PROJECT` | Run /clavix:prd |
| PRD exists, no tasks.md | `PRD_EXISTS` | Run /clavix:plan |
| tasks.md exists, no config | `TASKS_EXIST` | Run clavix implement |
| config.stats.remaining > 0 | `IMPLEMENTING` | Continue from currentTask |
| config.stats.remaining == 0 | `ALL_COMPLETE` | Suggest /clavix:archive |
| Project in archive/ directory | `ARCHIVED` | Use --restore to reactivate |

**Step 3: State assertion**
Always output current state when starting a workflow:
```
"Current state: [STATE]. Progress: [X]/[Y] tasks. Next: [action]"
```

### File Detection Guide

**PRD Files (check in order):**
1. `.clavix/outputs/{project}/full-prd.md` - Full PRD
2. `.clavix/outputs/{project}/quick-prd.md` - Quick PRD
3. `.clavix/outputs/{project}/mini-prd.md` - Mini PRD from summarize
4. `.clavix/outputs/prompts/*/optimized-prompt.md` - Saved prompts

**Task Files:**
- `.clavix/outputs/{project}/tasks.md` - Task breakdown

**Config Files:**
- `.clavix/outputs/{project}/.clavix-implement-config.json` - Implementation state

### State Transition Rules

```
NO_PROJECT:
  → /clavix:prd creates PRD_EXISTS
  → /clavix:start + /clavix:summarize creates PRD_EXISTS
  → /clavix:fast or /clavix:deep creates prompt (not PRD_EXISTS)

PRD_EXISTS:
  → /clavix:plan creates TASKS_EXIST
  → clavix plan command creates TASKS_EXIST

TASKS_EXIST:
  → clavix implement initializes config → IMPLEMENTING
  → /clavix:implement starts tasks → IMPLEMENTING

IMPLEMENTING:
  → clavix task-complete reduces remaining
  → When remaining == 0 → ALL_COMPLETE

ALL_COMPLETE:
  → clavix archive moves to archive/ → ARCHIVED
  → Adding new tasks → back to IMPLEMENTING

ARCHIVED:
  → clavix archive --restore → back to previous state
```

### Prompt Lifecycle States (Separate from PRD)

```
NO_PROMPTS → PROMPT_EXISTS → EXECUTED → CLEANED
```

| Condition | State | Detection |
|-----------|-------|-----------|
| No files in prompts/ | `NO_PROMPTS` | .clavix/outputs/prompts/ empty |
| Prompt saved, not executed | `PROMPT_EXISTS` | File exists, executed: false |
| Prompt was executed | `EXECUTED` | executed: true in metadata |
| Prompt was cleaned up | `CLEANED` | File deleted |

### Multi-Project Handling

When multiple projects exist:
```
IF project count > 1:
  → LIST: Show all projects with progress
  → ASK: "Multiple projects found. Which one?"
  → Options: [project names with % complete]
```

Project listing format:
```
Available projects:
  1. auth-feature (75% - 12/16 tasks)
  2. api-refactor (0% - not started)
  3. dashboard-v2 (100% - complete, suggest archive)
```


### Error Classification
## Error Classification for Agents

Errors are classified into three categories based on required agent response.

### RECOVERABLE Errors

Agent can fix automatically without user intervention.

| Error | Detection | Recovery Action |
|-------|-----------|-----------------|
| Directory missing | ENOENT on .clavix/ | Create directory, continue |
| Index file missing | ENOENT on .index.json | Initialize empty index, continue |
| Empty prompts directory | No files in prompts/ | Inform user "No prompts saved yet" |
| Stale config | timestamp > 7 days | Warn user, continue normally |
| Missing session | Session ID not found | Create new session |

**Recovery Protocol:**
```
IF error is RECOVERABLE:
  → FIX: Apply recovery action automatically
  → LOG: Note what was fixed
  → CONTINUE: Resume workflow
```

### BLOCKING Errors

Agent must stop and ask user before proceeding.

| Error | Detection | Agent Action |
|-------|-----------|--------------|
| Task not found | task-complete returns "not found" | ASK: "Task [id] not found in tasks.md. Verify the task ID?" |
| Multiple PRDs | >1 project detected | ASK: "Multiple projects found: [list]. Which one?" |
| Ambiguous intent | confidence <50% | ASK: "Unclear intent. Is this: [A] / [B] / [C]?" |
| Missing PRD for plan | No PRD files exist | ASK: "No PRD found. Create one with /clavix:prd first?" |
| Task blocked | External dependency | ASK: "Task blocked by [reason]. Skip or resolve?" |
| Overwrite conflict | File already exists | ASK: "File exists. Overwrite / Rename / Cancel?" |

**Blocking Protocol:**
```
IF error is BLOCKING:
  → STOP: Halt current operation
  → EXPLAIN: Clear description of the issue
  → OPTIONS: Present available choices
  → WAIT: For user response before continuing
```

### UNRECOVERABLE Errors

Agent must stop completely and report to user for manual resolution.

| Error | Detection | Agent Action |
|-------|-----------|--------------|
| Permission denied | EACCES error code | STOP. Report: "Permission denied on [path]. Check file permissions." |
| Corrupt JSON | JSON.parse throws | STOP. Report: "Config file corrupted at [path]. Manual fix required." |
| Git conflict | git command fails with conflict | STOP. Report: "Git conflict detected. Resolve manually before continuing." |
| Disk full | ENOSPC error | STOP. Report: "Disk full. Free up space before continuing." |
| Network timeout | ETIMEDOUT on external | STOP. Report: "Network timeout. Check connection and retry." |
| Invalid task ID format | Regex mismatch | STOP. Report: "Invalid task ID format: [id]. Expected: phase-N-name-M" |

**Unrecoverable Protocol:**
```
IF error is UNRECOVERABLE:
  → STOP: Halt all operations immediately
  → REPORT: Exact error with context
  → GUIDE: Manual steps to resolve
  → NO RETRY: Do not attempt automatic recovery
```

### Error Response Templates

**Recoverable:**
```
[Fixed] Created missing .clavix/ directory. Continuing...
```

**Blocking:**
```
[Blocked] Multiple projects found. Please select:
  1. auth-feature (75% complete)
  2. api-refactor (0% complete)

Which project should I work with?
```

**Unrecoverable:**
```
[Error] Cannot continue - manual intervention required.

Issue: Permission denied writing to /path/to/file
Cause: Insufficient file system permissions

To resolve:
  1. Check ownership: ls -la /path/to/
  2. Fix permissions: chmod 755 /path/to/
  3. Retry the operation

Once resolved, run the command again.
```

### Error Detection Patterns

**File System Errors:**
- `ENOENT` - File/directory not found → Usually RECOVERABLE
- `EACCES` - Permission denied → UNRECOVERABLE
- `EEXIST` - Already exists → BLOCKING (ask overwrite)
- `ENOSPC` - No space left → UNRECOVERABLE

**Git Errors:**
- "CONFLICT" in output → UNRECOVERABLE
- "not a git repository" → BLOCKING (ask to init)
- "nothing to commit" → RECOVERABLE (skip commit)

**JSON Errors:**
- `SyntaxError: Unexpected token` → UNRECOVERABLE
- Empty file → RECOVERABLE (initialize default)

**Task Errors:**
- Task ID not in tasks.md → BLOCKING
- Checkbox already checked → RECOVERABLE (skip)
- Invalid phase number → UNRECOVERABLE


### File Format Reference
## File Format Reference

### .clavix-implement-config.json

Implementation state configuration file.

**Location:** `.clavix/outputs/{project}/.clavix-implement-config.json`

**Schema:**
```json
{
  "commitStrategy": "per-task" | "per-5-tasks" | "per-phase" | "none",
  "tasksPath": "string - absolute path to tasks.md",
  "currentTask": {
    "id": "phase-N-name-M",
    "description": "Task description text",
    "phase": "Phase Name",
    "completed": false
  },
  "stats": {
    "total": 16,
    "completed": 4,
    "remaining": 12,
    "percentage": 25
  },
  "timestamp": "2024-01-15T10:30:00.000Z",
  "completedTaskIds": ["phase-1-setup-1", "phase-1-setup-2"],
  "blockedTasks": [
    {
      "taskId": "phase-2-auth-3",
      "reason": "Waiting for API keys",
      "timestamp": "2024-01-15T11:00:00.000Z"
    }
  ]
}
```

**Agent Usage Rules:**
- READ this file to determine current state
- NEVER modify directly - use `clavix task-complete` to update
- IF missing: Run `clavix implement` to initialize
- IF corrupted: Report as UNRECOVERABLE error

### tasks.md Format

Task breakdown file generated by /clavix:plan.

**Location:** `.clavix/outputs/{project}/tasks.md`

**Structure:**
```markdown
# Implementation Tasks: {Project Name}

Generated from: {PRD filename}
Created: {timestamp}

---

## Phase 1: {Phase Name}

- [ ] {Task description}
  - Task ID: `phase-1-{sanitized-name}-1`
  - PRD Reference: {section-name}

- [ ] {Another task}
  - Task ID: `phase-1-{sanitized-name}-2`

- [x] {Completed task}
  - Task ID: `phase-1-{sanitized-name}-3`

## Phase 2: {Phase Name}

- [ ] {Task description}
  - Task ID: `phase-2-{sanitized-name}-1`

---

## Progress Summary

- Total Tasks: {N}
- Completed: {M}
- Remaining: {N-M}
```

**Task ID Pattern:** `phase-{N}-{sanitized-name}-{M}`
- `N` = Phase number (1-indexed)
- `sanitized-name` = Lowercase, hyphens for spaces, no special chars
- `M` = Task counter within phase (1-indexed)

**Valid Examples:**
- `phase-1-setup-configuration-1`
- `phase-2-user-authentication-3`
- `phase-3-api-integration-2`

**Invalid Examples:**
- `phase1-setup-1` - Missing hyphen after "phase"
- `Phase-1-Setup-1` - Must be lowercase
- `phase-1-setup` - Missing task number

### .index.json (Prompts)

Index file for saved prompts.

**Location:** `.clavix/outputs/prompts/{type}/.index.json`

**Schema:**
```json
{
  "version": "1.0",
  "prompts": [
    {
      "id": "fast-20240115-103000-a1b2c3",
      "filename": "fast-20240115-103000-a1b2c3.md",
      "created": "2024-01-15T10:30:00.000Z",
      "intent": "code-generation",
      "quality": {
        "original": 42,
        "optimized": 78
      },
      "executed": false,
      "executedAt": null
    }
  ]
}
```

### PRD Files

**Full PRD:** `.clavix/outputs/{project}/full-prd.md`
- Complete team-facing document
- All sections expanded

**Quick PRD:** `.clavix/outputs/{project}/quick-prd.md`
- 2-3 paragraph AI-optimized version
- Key requirements only

**Mini PRD:** `.clavix/outputs/{project}/mini-prd.md`
- From /clavix:summarize
- Extracted from conversation

### Session Files

**Location:** `.clavix/sessions/{session-id}.json`

**Schema:**
```json
{
  "id": "session-uuid",
  "projectName": "optional-name",
  "status": "active" | "completed",
  "created": "2024-01-15T10:00:00.000Z",
  "updated": "2024-01-15T11:30:00.000Z",
  "messages": [
    {
      "role": "user" | "assistant",
      "content": "message text",
      "timestamp": "2024-01-15T10:05:00.000Z"
    }
  ],
  "tags": ["feature", "auth"],
  "description": "Optional session description"
}
```

### Directory Structure Overview

```
.clavix/
├── outputs/
│   ├── prompts/
│   │   ├── fast/
│   │   │   ├── .index.json
│   │   │   └── fast-{timestamp}-{hash}.md
│   │   └── deep/
│   │       ├── .index.json
│   │       └── deep-{timestamp}-{hash}.md
│   ├── {project-name}/
│   │   ├── full-prd.md
│   │   ├── quick-prd.md
│   │   ├── tasks.md
│   │   └── .clavix-implement-config.json
│   └── archive/
│       └── {archived-project}/
├── sessions/
│   └── {session-id}.json
└── config.json (global config)
```


### Agent Decision Rules
## Agent Decision Rules

These rules define deterministic agent behavior. Follow exactly - no interpretation needed.

### Rule 1: Quality-Based Mode Decision

```
IF quality < 60%:
  IF (completeness < 50%) OR (clarity < 50%) OR (actionability < 50%):
    → ACTION: Strongly recommend /clavix:deep
    → SAY: "Quality is [X]%. Deep mode strongly recommended for: [low dimensions]"
  ELSE:
    → ACTION: Suggest /clavix:deep
    → SAY: "Quality is [X]%. Consider deep mode for better results."

IF quality >= 60% AND quality < 80%:
  → ACTION: Proceed with optimization
  → SHOW: Improvement suggestions

IF quality >= 80%:
  → ACTION: Prompt is ready
  → SAY: "Prompt quality is good ([X]%). Ready to execute."
```

### Rule 2: Intent Confidence Decision

```
IF confidence >= 85%:
  → ACTION: Proceed with detected intent
  → NO secondary intent shown

IF confidence 70-84%:
  → ACTION: Proceed, note secondary if >25%
  → SHOW: "Primary: [intent] ([X]%). Also detected: [secondary] ([Y]%)"

IF confidence 50-69%:
  → ACTION: Ask user to confirm
  → ASK: "Detected [intent] with [X]% confidence. Is this correct?"

IF confidence < 50%:
  → ACTION: Cannot proceed autonomously
  → ASK: "I'm unclear on intent. Is this: [option A] | [option B] | [option C]?"
```

### Rule 3: Escalation Decision

```
IF escalation_score >= 75:
  → ACTION: Strongly recommend deep mode
  → SHOW: Top 3 contributing factors

IF escalation_score 60-74:
  → ACTION: Recommend deep mode
  → SHOW: Primary contributing factor

IF escalation_score 45-59:
  → ACTION: Suggest deep mode as option
  → SAY: "Deep mode available for more thorough analysis"

IF escalation_score < 45:
  → ACTION: Fast mode sufficient
  → NO escalation mention
```

### Rule 4: Task Completion (Implementation Mode)

```
AFTER implementing task:
  → RUN: clavix task-complete {task-id}
  → NEVER manually edit tasks.md checkboxes

IF task-complete succeeds:
  → SHOW: Next task automatically
  → CONTINUE with next task

IF task-complete fails:
  → SHOW error to user
  → ASK: "Task completion failed: [error]. How to proceed?"
```

### Rule 5: Workflow State Check

```
BEFORE starting /clavix:implement:
  → CHECK: .clavix-implement-config.json exists?

  IF exists AND stats.remaining > 0:
    → SAY: "Resuming implementation. Progress: [X]/[Y] tasks."
    → CONTINUE from currentTask

  IF exists AND stats.remaining == 0:
    → SAY: "All tasks complete. Consider /clavix:archive"

  IF not exists:
    → RUN: clavix implement (to initialize)
```

### Rule 6: File Operations

```
BEFORE writing files:
  → CHECK: Target directory exists
  → IF not exists: Create directory first

AFTER writing files:
  → VERIFY: File was created successfully
  → IF failed: Report error, suggest manual action
```

### Rule 7: Pattern Application Decision

```
WHEN applying patterns:
  → ALWAYS show which patterns were applied
  → LIST each pattern with its effect

IF pattern not applicable to intent:
  → SKIP silently (no output)

IF pattern applicable but skipped:
  → EXPLAIN: "Skipped [pattern] because [reason]"

DEEP MODE ONLY:
  → MUST include alternatives (2-3)
  → MUST include validation checklist
  → MUST include edge cases
```

### Rule 8: Mode Transition Decision

```
IF user requests /clavix:fast but quality < 50%:
  → ACTION: Warn and suggest deep
  → SAY: "Quality is [X]%. Fast mode may be insufficient."
  → ALLOW: User can override and proceed

IF user in /clavix:deep but prompt is simple (quality > 85%):
  → ACTION: Note efficiency
  → SAY: "Prompt is already high quality. Fast mode would suffice."
  → CONTINUE: With deep analysis anyway

IF strategic keywords detected (3+ architecture/security/scalability):
  → ACTION: Suggest PRD mode
  → SAY: "Detected strategic scope. Consider /clavix:prd for comprehensive planning."
```

### Rule 9: Output Validation Decision

```
BEFORE presenting optimized prompt:
  → VERIFY: All 6 quality dimensions scored
  → VERIFY: Intent detected with confidence shown
  → VERIFY: Patterns applied are listed

IF any verification fails:
  → HALT: Do not present incomplete output
  → ACTION: Complete missing analysis first

AFTER optimization complete:
  → MUST save prompt to .clavix/outputs/prompts/
  → MUST update index file
  → SHOW: "✓ Prompt saved: [filename]"
```

### Rule 10: Error Recovery Decision

```
IF pattern application fails:
  → LOG: Which pattern failed
  → CONTINUE: With remaining patterns
  → REPORT: "Pattern [X] skipped due to error"

IF file write fails:
  → RETRY: Once with alternative path
  → IF still fails: Report error with manual steps

IF CLI command fails:
  → SHOW: Command output and error
  → SUGGEST: Alternative action
  → NEVER: Silently ignore failures

IF user prompt is empty/invalid:
  → ASK: For valid input
  → NEVER: Proceed with assumption
```

### Rule 11: Execution Verification (v4.6)

```
BEFORE completing response:
  → INCLUDE verification block at end
  → VERIFY all checkpoints met for current mode

  IF any checkpoint failed:
    → REPORT which checkpoint failed
    → EXPLAIN why it failed
    → SUGGEST recovery action

  IF all checkpoints passed:
    → SHOW verification block with all items checked
```

**Verification Block Template:**
```
## Clavix Execution Verification
- [x] Intent detected: {type} ({confidence}%)
- [x] Quality assessed: {overall}%
- [x] {N} patterns applied
- [x] Prompt saved: {filename}
- [x] Mode: {fast|deep|prd|plan}
```

---

### Rule Summary Table

| Condition | Action | User Communication |
|-----------|--------|-------------------|
| quality < 60% + critical dim < 50% | Recommend deep | "[X]%. Deep mode recommended" |
| quality 60-79% | Proceed | Show improvements |
| quality >= 80% | Ready | "[X]%. Ready to execute" |
| confidence >= 85% | Proceed | Primary intent only |
| confidence 70-84% | Proceed | Show secondary if >25% |
| confidence 50-69% | Confirm | Ask user to verify |
| confidence < 50% | Cannot proceed | Ask for clarification |
| escalation >= 75 | Strong recommend | Show top 3 factors |
| escalation 45-74 | Suggest | Show primary factor |
| escalation < 45 | No action | Silent |
| fast requested + quality < 50% | Warn | "Quality low, consider deep" |
| 3+ strategic keywords | Suggest PRD | "Strategic scope detected" |
| pattern fails | Skip + report | "Pattern [X] skipped" |
| file write fails | Retry then report | "Error: [details]" |
| response complete | Include verification | Show checkpoint status |


---

## Troubleshooting

### Issue: `.clavix-implement-config.json` not found
**Cause**: User hasn't run `clavix implement` CLI command first
**Solution** (inline):
- Error: "Config file not found. Run `clavix implement` first to initialize"
- CLI creates config and shows first task
- AI agent should wait for config before proceeding

### Issue: `clavix task-complete` command not found
**Cause**: Clavix version doesn't have task-complete command OR not in PATH
**Solution**:
- Check Clavix version: `clavix --version`
- Ensure Clavix is up to date: `npm install -g clavix@latest`
- If issue persists, report bug to Clavix maintainers

### Issue: Task ID not found by task-complete
**Cause**: Task ID doesn't match what's in tasks.md
**Solution**:
- Read tasks.md to see actual task IDs
- Task IDs follow pattern: `{sanitized-phase-name}-{counter}`
- Run `clavix task-complete` without arguments to see available tasks
- Example: `phase-1-authentication-1` not `Phase 1 Authentication 1`

### Issue: Task already marked complete
**Cause**: Task was completed in previous session or manually
**Solution**:
- Use `--force` flag: `clavix task-complete {task-id} --force`
- Or skip to next task shown by `clavix implement`
- Config will be updated to track the completion

### Issue: Cannot find next incomplete task in tasks.md
**Cause**: All tasks completed OR tasks.md corrupted
**Solution**:
- Check if all tasks are `[x]` - if yes, congratulate completion!
- Suggest `/clavix:archive` for completed project
- If tasks.md corrupted, ask user to review/regenerate

### Issue: Task description unclear or conflicts with PRD
**Cause**: Task breakdown was too vague or PRD changed
**Solution** (inline - covered by Task Blocking Protocol):
- Stop and ask user for clarification
- Reference PRD section if mentioned
- Propose interpretation for user approval
- Update task description in tasks.md after clarification

### Issue: Git commit fails (wrong strategy, hook error, etc.)
**Cause**: Git configuration issue or commit hook failure
**Solution**:
- Show error to user
- Suggest checking git status manually
- Ask if should continue without commit or fix issue first
- Note: Commits are convenience, not blocker - can proceed without

### Issue: Multiple [BLOCKED] tasks accumulating
**Cause**: Dependencies or blockers not being resolved
**Solution**:
- After 3+ blocked tasks, pause and report to user
- List all blockers and what's needed to resolve
- Ask user to prioritize: unblock tasks OR continue with unblocked ones
- Consider if project should be paused until blockers cleared

### Issue: Task completed but tests failing
**Cause**: Implementation doesn't meet requirements
**Solution**:
- Do NOT mark task as complete if tests fail
- Fix failing tests before marking [x]
- If tests are incorrectly written, fix tests first
- Task isn't done until tests pass

### Issue: Implementing in wrong order (skipped dependencies)
**Cause**: AI agent or user jumped ahead
**Solution**:
- Stop and review tasks.md order
- Check if skipped task was a dependency
- Implement missed dependency first
- Follow sequential order unless explicitly instructed otherwise