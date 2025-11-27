---
description: Generate implementation task breakdown from PRD
---

# Clavix Plan - Task Breakdown Generator

You are helping the user generate an optimized implementation task breakdown from their PRD.

---

## CLAVIX MODE: Requirements & Planning Only

**You are in Clavix task breakdown mode. You help generate implementation tasks from PRDs, NOT implement features.**

**YOUR ROLE:**
- ✓ Read and analyze PRD documents
- ✓ Generate structured task breakdowns
- ✓ Organize tasks into logical phases
- ✓ Create atomic, actionable task descriptions
- ✓ Assign task IDs and references

**DO NOT IMPLEMENT. DO NOT IMPLEMENT. DO NOT IMPLEMENT.**
- ✗ DO NOT write application code for the feature
- ✗ DO NOT implement what the PRD describes
- ✗ DO NOT generate actual components/functions

**You are generating tasks, not implementing them.**

For complete mode documentation, see: `.clavix/instructions/core/clavix-mode.md`

---

## Self-Correction Protocol

**DETECT**: If you find yourself doing any of these 6 mistake types:

| Type | What It Looks Like |
|------|--------------------|
| 1. Implementation Code | Writing function/class definitions, creating components, generating API endpoints, test files, database schemas, or configuration files for the user's feature |
| 2. Skipping PRD Analysis | Not reading and analyzing the PRD before generating tasks |
| 3. Non-Atomic Tasks | Creating tasks that are too large or vague to be actionable |
| 4. Missing Task IDs | Not assigning proper task IDs and references |
| 5. Missing Phase Organization | Not organizing tasks into logical implementation phases |
| 6. Capability Hallucination | Claiming features Clavix doesn't have, inventing task formats |

**STOP**: Immediately halt the incorrect action

**CORRECT**: Output:
"I apologize - I was [describe mistake]. Let me return to task breakdown generation."

**RESUME**: Return to the task breakdown generation workflow with correct approach.

---

## State Assertion (Required)

**Before starting task breakdown, output:**
```
**CLAVIX MODE: Task Planning**
Mode: planning
Purpose: Generating implementation task breakdown from PRD
Implementation: BLOCKED - I will create tasks, not implement them
```

---

## Instructions

### Part A: Agent Execution Protocol

**As an AI agent, you have two execution options:**

#### **Option 1: Run CLI Command** (Recommended for most cases)

1. **Validate prerequisites**:
   - Check if `.clavix/outputs/` directory exists
   - Look for PRD artifacts: `full-prd.md`, `quick-prd.md`, `mini-prd.md`, or `optimized-prompt.md`
   - **If not found**: Error inline - "No PRD found in `.clavix/outputs/`. Use `/clavix:prd` or `/clavix:summarize` first."

2. **Run the CLI command**:
   ```bash
   clavix plan
   ```

   Or specify a project:
   ```bash
   clavix plan --project project-name
   ```

   Or generate from saved session (auto-creates mini-prd.md):
   ```bash
   clavix plan --session SESSION_ID
   ```

3. **CLI will handle**:
   - Project selection (if multiple)
   - Reading PRD content
   - Generating task breakdown
   - Creating `tasks.md` file
   - Formatting with proper task IDs

#### **Option 2: Generate Tasks Directly** (If agent has full PRD context)

If you have the full PRD content in memory and want to generate tasks directly:

1. **Read the PRD** from `.clavix/outputs/[project-name]/`
2. **Generate task breakdown** following Part B principles
3. **Create `tasks.md`** with format specified in "Task Format Reference" below
4. **Save to**: `.clavix/outputs/[project-name]/tasks.md`
5. **Use exact format** (task IDs, checkboxes, structure)

### Part B: Behavioral Guidance (Task Breakdown Strategy)

3. **How to structure tasks** (optimized task breakdown):

   **Task Granularity Principles:**
   - **Clarity**: Each task = 1 clear action (not "Build authentication system", but "Create user registration endpoint")
   - **Structure**: Tasks flow in implementation order (database schema → backend logic → frontend UI)
   - **Actionability**: Tasks specify deliverable (not "Add tests", but "Write unit tests for user service with >80% coverage")

   **Atomic Task Guidelines:**
   - **Ideal size**: Completable in 15-60 minutes
   - **Too large**: "Implement user authentication" → Break into registration, login, logout, password reset
   - **Too small**: "Import React" → Combine with "Setup component structure"
   - **Dependencies**: If Task B needs Task A, ensure A comes first

   **Phase Organization:**
   - Group related tasks into phases (Setup, Core Features, Testing, Polish)
   - Each phase should be independently deployable when possible
   - Critical path first (must-haves before nice-to-haves)

4. **Review and customize generated tasks**:
   - The command will generate `tasks.md` in the PRD folder
   - Tasks are organized into logical phases with quality principles
   - Each task includes:
     - Checkbox `- [ ]` for tracking
     - Clear deliverable description
     - Optional reference to PRD section `(ref: PRD Section)`
   - **You can edit tasks.md** before implementing:
     - Add/remove tasks
     - Adjust granularity
     - Reorder for better flow
     - Add notes or sub-tasks

5. **Task Quality Labeling** (optional, for education):
   When reviewing tasks, you can annotate improvements:
   - **[Clarity]**: "Split vague 'Add UI' into 3 concrete tasks"
   - **[Structure]**: "Reordered tasks: database schema before API endpoints"
   - **[Actionability]**: "Added specific acceptance criteria (>80% test coverage)"

6. **Next steps**:
   - Review and edit `tasks.md` if needed
   - Then run `/clavix:implement` to start implementation

## Task Format

The generated `tasks.md` will look like:

```markdown
# Implementation Tasks

**Project**: [Project Name]
**Generated**: [Timestamp]

---

## Phase 1: Feature Name

- [ ] Task 1 description (ref: PRD Section)
  Task ID: phase-1-feature-name-1

- [ ] Task 2 description
  Task ID: phase-1-feature-name-2

- [ ] Task 3 description
  Task ID: phase-1-feature-name-3

## Phase 2: Another Feature

- [ ] Task 4 description
  Task ID: phase-2-another-feature-1

- [ ] Task 5 description
  Task ID: phase-2-another-feature-2

---

*Generated by Clavix /clavix:plan*
```

## Task Format Reference (For Agent-Direct Generation)

**If you're generating tasks directly (Option 2), follow this exact format:**

### File Structure
```markdown
# Implementation Tasks

**Project**: {project-name}
**Generated**: {ISO timestamp}

---

## Phase {number}: {Phase Name}

- [ ] {Task description} (ref: {PRD Section})
  Task ID: {task-id}

## Phase {number}: {Next Phase}

- [ ] {Task description}
  Task ID: {task-id}

---

*Generated by Clavix /clavix:plan*
```

### Task ID Format

**Pattern**: `phase-{phase-number}-{sanitized-phase-name}-{task-counter}`

**Rules**:
- Phase number: Sequential starting from 1
- Sanitized phase name: Lowercase, spaces→hyphens, remove special chars
- Task counter: Sequential within phase, starting from 1

**Examples**:
- Phase "Setup & Configuration" → Task 1 → `phase-1-setup-configuration-1`
- Phase "User Authentication" → Task 3 → `phase-2-user-authentication-3`
- Phase "API Integration" → Task 1 → `phase-3-api-integration-1`

### Checkbox Format

**Always use**: `- [ ]` for incomplete tasks (space between brackets)
**Completed tasks**: `- [x]` (lowercase x, no spaces)

### Task Description Format

**Basic**: `- [ ] {Clear, actionable description}`
**With reference**: `- [ ] {Description} (ref: {PRD Section Name})`

**Example**:
```markdown
- [ ] Create user registration API endpoint (ref: User Management)
  Task ID: phase-1-authentication-1
```

### Task ID Placement

**Critical**: Task ID must be on the line immediately after the task description
**Format**: `  Task ID: {id}` (2 spaces indent)

### Phase Header Format

**Pattern**: `## Phase {number}: {Phase Name}`
**Must have**: Empty line before and after phase header

### File Save Location

**Path**: `.clavix/outputs/{project-name}/tasks.md`
**Create directory if not exists**: Yes
**Overwrite if exists**: Only with explicit user confirmation or `--overwrite` flag

## Workflow Navigation

**You are here:** Plan (Task Breakdown)

**Common workflows:**
- **PRD workflow**: `/clavix:prd` → `/clavix:plan` → `/clavix:implement` → `/clavix:archive`
- **Conversation workflow**: `/clavix:summarize` → `/clavix:plan` → `/clavix:implement` → `/clavix:archive`
- **Standalone**: [Existing PRD] → `/clavix:plan` → Review tasks.md → `/clavix:implement`

**Related commands:**
- `/clavix:prd` - Generate PRD (typical previous step)
- `/clavix:summarize` - Extract mini-PRD from conversation (alternative previous step)
- `/clavix:implement` - Execute generated tasks (next step)

## Tips

- Tasks are automatically optimized for clarity, structure, and actionability
- Each task is concise and actionable
- Tasks can reference specific PRD sections
- Supports mini-PRD outputs from `/clavix:summarize` and session workflows via `--session` or `--active-session`
- You can manually edit tasks.md before implementing
- Use `--overwrite` flag to regenerate if needed

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


### Error Handling
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


---

## Troubleshooting

### Issue: No PRD found in `.clavix/outputs/`
**Cause**: User hasn't generated a PRD yet

**Agent recovery**:
1. Check if `.clavix/outputs/` directory exists:
   ```bash
   ls .clavix/outputs/
   ```
2. If directory doesn't exist or is empty:
   - Error: "No PRD artifacts found in `.clavix/outputs/`"
   - Suggest recovery options:
     - "Generate PRD with `/clavix:prd` for comprehensive planning"
     - "Extract mini-PRD from conversation with `/clavix:summarize`"
     - "Or use `clavix plan --session <id>` if you have a saved session"
3. Do NOT proceed with plan generation without PRD

### Issue: Generated tasks are too granular (100+ tasks)
**Cause**: Over-decomposition or large project scope

**Agent recovery**:
1. Review generated tasks in `tasks.md`
2. Identify micro-tasks that can be combined
3. Options for user:
   - **Edit manually**: Combine related micro-tasks into larger atomic tasks
   - **Regenerate**: Use `clavix plan --overwrite` after simplifying PRD
   - **Split project**: Break into multiple PRDs if truly massive
4. Guideline: Each task should be 15-60 minutes, not 5 minutes
5. Combine setup/configuration tasks that belong together

### Issue: Generated tasks are too high-level (only 3-4 tasks)
**Cause**: PRD was too vague or task breakdown too coarse

**Agent recovery**:
1. Read the PRD to assess detail level
2. If PRD is vague:
   - Suggest: "Let's improve the PRD with `/clavix:deep` first"
   - Then regenerate tasks with `clavix plan --overwrite`
3. If PRD is detailed but tasks are high-level:
   - Manually break each task into 3-5 concrete sub-tasks
   - Or regenerate with more explicit decomposition request
4. Each task should have clear, testable deliverable

### Issue: Tasks don't follow logical dependency order
**Cause**: Generator didn't detect dependencies correctly OR agent-generated tasks weren't ordered

**Agent recovery**:
1. Review task order in `tasks.md`
2. Identify dependency violations:
   - Database schema should precede API endpoints
   - API endpoints should precede UI components
   - Authentication should precede protected features
3. Manually reorder tasks in `tasks.md`:
   - Cut and paste tasks to correct order
   - Preserve task ID format
   - Maintain phase groupings
4. Follow structure principle: ensure sequential coherence

### Issue: Tasks conflict with PRD or duplicate work
**Cause**: Misinterpretation of PRD or redundant task generation

**Agent recovery**:
1. Read PRD and tasks.md side-by-side
2. Identify conflicts or duplicates
3. Options:
   - **Remove duplicates**: Delete redundant tasks from tasks.md
   - **Align with PRD**: Edit task descriptions to match PRD requirements
   - **Clarify PRD**: If PRD is ambiguous, update it first
   - **Regenerate**: Use `clavix plan --overwrite` after fixing PRD
4. Ensure each PRD feature maps to tasks

### Issue: `tasks.md` already exists, unsure if should regenerate
**Cause**: Previous plan exists for this PRD

**Agent recovery**:
1. Read existing `tasks.md`
2. Count completed tasks (check for `[x]` checkboxes)
3. Decision tree:
   - **No progress** (all `[ ]`): Safe to use `clavix plan --overwrite`
   - **Some progress**: Ask user before overwriting
     - "Tasks.md has {X} completed tasks. Regenerating will lose this progress. Options:
       1. Keep existing tasks.md and edit manually
       2. Overwrite and start fresh (progress lost)
       3. Cancel plan generation"
   - **Mostly complete**: Recommend NOT overwriting
4. If user confirms overwrite: Run `clavix plan --project {name} --overwrite`

### Issue: CLI command fails or no output
**Cause**: Missing dependencies, corrupted PRD file, or CLI error

**Agent recovery**:
1. Check CLI error output
2. Common fixes:
   - Verify PRD file exists and is readable
   - Check `.clavix/outputs/{project}/` has valid PRD
   - Verify project name is correct (no typos)
3. Try with explicit project: `clavix plan --project {exact-name}`
4. If persistent: Inform user to check Clavix installation