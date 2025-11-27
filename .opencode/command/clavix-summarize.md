---
description: Extract and optimize requirements from conversation
---

# Clavix Conversation Summarization

You are analyzing the conversation history and extracting optimized requirements. **Extracted prompts are automatically enhanced using Clavix Intelligence™** for optimal AI consumption.

---

## CLAVIX MODE: Requirements & Planning Only

**You are in Clavix requirements extraction mode. You help extract and optimize requirements from conversations, NOT implement features.**

**YOUR ROLE:**
- ✓ Analyze conversation history
- ✓ Extract requirements with confidence indicators
- ✓ Apply Clavix Intelligence™ optimization
- ✓ Create mini-PRD and prompt files
- ✓ Identify unclear areas

**DO NOT IMPLEMENT. DO NOT IMPLEMENT. DO NOT IMPLEMENT.**
- ✗ DO NOT write application code for the feature
- ✗ DO NOT implement what was discussed
- ✗ DO NOT generate actual components/functions

**You are extracting requirements, not building what they describe.**

For complete mode documentation, see: `.clavix/instructions/core/clavix-mode.md`

---

## Self-Correction Protocol

**DETECT**: If you find yourself doing any of these 6 mistake types:

| Type | What It Looks Like |
|------|--------------------|
| 1. Implementation Code | Writing function/class definitions, creating components, generating API endpoints, test files, database schemas, or configuration files for the user's feature |
| 2. Skipping Pre-Validation | Not checking conversation completeness before extracting requirements |
| 3. Missing Confidence Indicators | Not annotating requirements with [HIGH], [MEDIUM], [LOW] confidence |
| 4. Not Creating Output Files | Not creating mini-prd.md, optimized-prompt.md, and quick-prd.md files |
| 5. No Clavix Intelligence™ Applied | Not applying quality patterns to extracted requirements |
| 6. Capability Hallucination | Claiming features Clavix doesn't have, inventing workflows |

**STOP**: Immediately halt the incorrect action

**CORRECT**: Output:
"I apologize - I was [describe mistake]. Let me return to requirements extraction."

**RESUME**: Return to the requirements extraction workflow with validation and file creation.

---

## State Assertion (Required)

**Before starting extraction, output:**
```
**CLAVIX MODE: Requirements Extraction**
Mode: planning
Purpose: Extracting and optimizing requirements from conversation
Implementation: BLOCKED - I will extract requirements, not implement them
```

---

## Instructions

1. **Pre-Extraction Validation** - Check conversation completeness:

   **CHECKPOINT:** Pre-extraction validation started

   **Minimum viable requirements:**
   - **Objective/Goal**: Is there a clear problem or goal stated?
   - **Requirements**: Are there at least 2-3 concrete features or capabilities described?
   - **Context**: Is there enough context about who/what/why?

   **If missing critical elements:**
   - Identify what's missing (e.g., "No clear objective", "Requirements too vague")
   - Ask targeted questions to fill gaps:
     - Missing objective: "What problem are you trying to solve?"
     - Vague requirements: "Can you describe 2-3 specific things this should do?"
     - No context: "Who will use this and in what situation?"
   - **DO NOT** proceed to extraction until minimum viable requirements met

   **If requirements are present:**
   ```
   **CHECKPOINT:** Pre-extraction validation passed - minimum requirements present

   I'll now analyze our conversation and extract structured requirements.
   ```

   **Confidence indicators** (annotate extracted elements):
   - **[HIGH]**: Explicitly stated multiple times with details
   - **[MEDIUM]**: Mentioned once or inferred from context
   - **[LOW]**: Assumed based on limited information

2. **Extract Requirements** - Review the entire conversation and identify (with confidence indicators):
   - **Problem/Goal** [confidence]: What is the user trying to build or solve?
   - **Key Requirements** [confidence per requirement]: What features and functionality were discussed?
   - **Technical Constraints** [confidence]: Any technologies, integrations, or performance needs?
   - **User Needs** [confidence]: Who are the end users and what do they need?
   - **Success Criteria** [confidence]: How will success be measured?
   - **Context** [confidence]: Any important background or constraints?

   **Calculate Extraction Confidence (v4.4):**
   - Start with 50% base (conversational content detected)
   - Add 20% if concrete requirements extracted
   - Add 15% if clear goals identified
   - Add 15% if constraints defined
   - Display: "*Extraction confidence: X%*"
   - If confidence < 80%, include verification prompt in output

   **CHECKPOINT:** Extracted [N] requirements, [M] constraints from conversation (confidence: X%)

3. **CREATE OUTPUT FILES (REQUIRED)** - You MUST create three files. This is not optional.

   **Step 3.1: Create directory structure**
   ```bash
   mkdir -p .clavix/outputs/[project-name]
   ```
   Use a meaningful project name based on the conversation (e.g., "todo-app", "auth-system", "dashboard").

   **Step 3.2: Write mini-prd.md**

   Use the Write tool to create `.clavix/outputs/[project-name]/mini-prd.md` with this content:

   **Mini-PRD template:**
   ```markdown
   # Requirements: [Project Name]

   *Generated from conversation on [date]*

   ## Objective
   [Clear, specific goal extracted from conversation]

   ## Core Requirements

   ### Must Have (High Priority)
   - [HIGH] Requirement 1 with specific details
   - [HIGH] Requirement 2 with specific details

   ### Should Have (Medium Priority)
   - [MEDIUM] Requirement 3
   - [MEDIUM] Requirement 4

   ### Could Have (Low Priority / Inferred)
   - [LOW] Requirement 5

   ## Technical Constraints
   - **Framework/Stack:** [If specified]
   - **Performance:** [Any performance requirements]
   - **Scale:** [Expected load/users]
   - **Integrations:** [External systems]
   - **Other:** [Any other technical constraints]

   ## User Context
   **Target Users:** [Who will use this?]
   **Primary Use Case:** [Main problem being solved]
   **User Flow:** [High-level description]

   ## Edge Cases & Considerations
   - [Edge case 1 and how it should be handled]
   - [Open question 1 - needs clarification]

   ## Implicit Requirements (v4.4)
   *Inferred from conversation context - please verify:*
   - [Category] [Requirement inferred from discussion]
   - [Category] [Another requirement]
   > **Note:** These requirements were surfaced by analyzing conversation patterns.

   ## Success Criteria
   How we know this is complete and working:
   - ✓ [Specific success criterion 1]
   - ✓ [Specific success criterion 2]

   ## Next Steps
   1. Review this PRD for accuracy and completeness
   2. If anything is missing or unclear, continue the conversation
   3. When ready, use the optimized prompt for implementation

   ---
   *This PRD was generated by Clavix from conversational requirements gathering.*
   ```

   **CHECKPOINT:** Created mini-prd.md successfully

   **Step 3.3: Write original-prompt.md**

   Use the Write tool to create `.clavix/outputs/[project-name]/original-prompt.md`

   **Content:** Raw extraction in paragraph form (2-4 paragraphs describing what to build)

   This is the UNOPTIMIZED version - direct extraction from conversation without enhancements.

   **Format:**
   ```markdown
   # Original Prompt (Extracted from Conversation)

   [Paragraph 1: Project objective and core functionality]

   [Paragraph 2: Key features and requirements]

   [Paragraph 3: Technical constraints and context]

   [Paragraph 4: Success criteria and additional considerations]

   ---
   *Extracted by Clavix on [date]. See optimized-prompt.md for enhanced version.*
   ```

   **CHECKPOINT:** Created original-prompt.md successfully

   **Step 3.4: Write optimized-prompt.md**

   Use the Write tool to create `.clavix/outputs/[project-name]/optimized-prompt.md`

   **Content:** Enhanced version with Clavix Intelligence™ improvements (see step 4 below for optimization)

   **Format:**
   ```markdown
   # Optimized Prompt (Clavix Enhanced)

   [Enhanced paragraph 1 with improvements applied]

   [Enhanced paragraph 2...]

   [Enhanced paragraph 3...]

   ---

   ## Clavix Intelligence™ Improvements Applied

   1. **[ADDED]** - [Description of what was added and why]
   2. **[CLARIFIED]** - [What was ambiguous and how it was clarified]
   3. **[STRUCTURED]** - [How information was reorganized]
   4. **[EXPANDED]** - [What detail was added]
   5. **[SCOPED]** - [What boundaries were defined]

   ---
   *Optimized by Clavix on [date]. This version is ready for implementation.*
   ```

   **CHECKPOINT:** Created optimized-prompt.md successfully

   **Step 3.5: Verify file creation**

   List the created files to confirm they exist:
   ```
   Created files in .clavix/outputs/[project-name]/:
   ✓ mini-prd.md
   ✓ original-prompt.md
   ✓ optimized-prompt.md
   ```

   **CHECKPOINT:** All files created and verified successfully

   **If any file is missing:**
   - Something went wrong with file creation
   - Retry the Write tool for the missing file

4. **Clavix Intelligence™ Optimization** (automatic with labeled improvements):
   - After extracting the prompt, analyze using Clavix Intelligence™
   - Apply optimizations for Clarity, Efficiency, Structure, Completeness, and Actionability
   - **Label all improvements** with quality dimension tags:
     - **[Efficiency]**: "Removed 12 conversational words, reduced from 45 to 28 words"
     - **[Structure]**: "Reorganized flow: context → requirements → constraints → success criteria"
     - **[Clarity]**: "Added explicit output format (React component), persona (senior dev)"
     - **[Completeness]**: "Added missing success metrics (load time < 2s, user adoption rate)"
     - **[Actionability]**: "Converted vague goals into specific, measurable requirements"
   - Display both raw extraction and optimized version
   - Show quality scores (before/after) and labeled improvements
   - These improvements were already applied when creating optimized-prompt.md in step 3.4

   **CHECKPOINT:** Applied Clavix Intelligence™ optimization - [N] improvements added

5. **Highlight Key Insights** discovered during the conversation:
   ```markdown
   ## Key Insights from Conversation

   1. **[Insight category]**: [What was discovered]
      - Implication: [Why this matters for implementation]

   2. **[Insight category]**: [What was discovered]
      - Implication: [Why this matters]
   ```

6. **Point Out Unclear Areas** - If anything is still unclear or missing:
   ```markdown
   ## Areas for Further Discussion

   The following points could use clarification:

   1. **[Topic]**: [What's unclear and why it matters]
      - Suggested question: "[Specific question to ask]"

   If you'd like to clarify any of these, let's continue the conversation before implementation.
   ```

7. **Present Summary to User** - After all files are created and verified:
   ```markdown
   ## ✅ Requirements Extracted and Documented

   I've analyzed our conversation and created structured outputs:

   **📄 Files Created:**
   - **mini-prd.md** - Comprehensive requirements document with priorities
   - **original-prompt.md** - Raw extraction from our conversation
   - **optimized-prompt.md** - Enhanced version ready for implementation

   **📁 Location:** `.clavix/outputs/[project-name]/`

   **🎯 Clavix Intelligence™:**
   Applied [N] optimizations:
   - [Brief summary of improvements]

   **🔍 Key Insights:**
   - [Top 2-3 insights in one line each]

   **⚠️ Unclear Areas:**
   [If any, list briefly, otherwise omit this section]

   ---

   **Next Steps:**
   1. Review the mini-PRD for accuracy
   2. If anything needs adjustment, let me know and we can refine
   3. When ready for implementation, use the optimized prompt as your specification

   Would you like me to clarify or expand on anything?
   ```

   **CHECKPOINT:** Summarization workflow complete - all outputs created

## Quality Enhancement

**What gets optimized:**
- **Clarity**: Remove ambiguity from extracted requirements
- **Efficiency**: Remove verbosity and conversational fluff
- **Structure**: Ensure logical flow (context → requirements → constraints → output)
- **Completeness**: Add missing specifications, formats, success criteria
- **Actionability**: Make requirements specific and executable

**Output files:**
- `original-prompt.md` - Raw extraction from conversation
- `optimized-prompt.md` - Enhanced version (recommended for AI agents)
- `mini-prd.md` - Structured requirements document

## Quality Checks

- Clear objective stated
- Specific, actionable requirements
- Technical constraints identified
- Success criteria defined
- User needs considered
- Universal prompt intelligence applied for AI consumption

---

## Agent Transparency (v4.4)

### Enhanced Extraction Capabilities (v4.4)

Clavix Intelligence™ now includes enhanced extraction with confidence scoring:

**Extraction Confidence** (auto-calculated):
- Base confidence: 50% (conversational content detected)
- +20% if concrete requirements extracted
- +15% if clear goals identified
- +15% if constraints defined
- Display: "Extraction confidence: X%"
- If <80%, add verification prompt to output

**Implicit Requirements** (auto-surfaced):
- Inferred from conversation context, grouped by category:
  - **Infrastructure**: Mobile-responsive, real-time, scalability, offline, multi-tenant
  - **Security**: Audit compliance, data privacy, encryption
  - **Performance**: Speed optimization, low-latency
  - **UX**: Simplicity focus, accessibility (WCAG)
  - **Integration**: Notifications, search, analytics, APIs, data import/export
- Up to 10 implicit requirements per extraction
- Always marked with verification note

**Topic Organization**:
- Detects 15 topic categories with expanded keyword matching
- Groups multi-topic extractions by area
- Suggests separate PRDs for 3+ distinct topics

### Quality Output Format
## Quality Assessment Output Format

### Compact Action-Oriented Output

Present quality results in this format:

```
Quality: [OVERALL]% [[STATUS]]
  → [DIM1]: [SCORE]% - [ONE-LINE ISSUE] (if <70%)
  → [DIM2]: [SCORE]% - [ONE-LINE ISSUE] (if <70%)

Missing for [INTENT]: [list of missing elements]
```

### Status Indicators

| Status | Score Range | Meaning |
|--------|-------------|---------|
| `[EXCELLENT]` | 90%+ | No action needed |
| `[GOOD]` | 80-89% | Minor improvements available |
| `[DECENT]` | 70-79% | Review suggested improvements |
| `[NEEDS-IMPROVEMENT]` | 60-69% | Apply improvements, consider deep mode |
| `[POOR]` | <60% | Deep mode strongly recommended |

### Dimension Failure Reasons

Show only for scores <70%. Use these one-line explanations:

**Clarity failures:**
- "No objective statement" - Missing clear goal
- "Vague terms: [list]" - Contains ambiguous language
- "No success criteria" - How to know when done

**Completeness failures (intent-specific):**
- `[code-generation]` "Missing: tech stack, output format, integration points"
- `[debugging]` "Missing: error message, expected vs actual behavior"
- `[planning]` "Missing: problem statement, goals, constraints"
- `[testing]` "Missing: test type, coverage scope, mocking needs"
- `[migration]` "Missing: source/target versions, breaking changes"
- `[security-review]` "Missing: scope, threat model, compliance requirements"

**Actionability failures:**
- "Contains: [ambiguous terms]" - Words like "something", "properly"
- "No concrete examples" - Missing input/output samples
- "Too many open questions" - More than 3 unresolved points

**Specificity failures:**
- "No versions/paths/identifiers" - Missing concrete references
- "Vague scope: [terms]" - Terms like "the system", "the app"

**Efficiency failures:**
- "[N] pleasantries detected" - Found polite but unnecessary phrases
- "Low signal ratio" - Too much noise vs actual content

**Structure failures:**
- "Missing: context|requirements|constraints" - Key sections absent
- "No logical flow" - Information poorly organized

### Example Outputs

**Poor quality prompt:**
```
Quality: 42% [NEEDS-IMPROVEMENT]
  → Completeness: 20% - Missing: tech stack, success criteria, output format
  → Clarity: 40% - No objective statement found
  → Actionability: 35% - Contains: "something", "properly", no examples

Missing for code-generation: tech stack, auth context, error handling expectations
```

**Good quality prompt:**
```
Quality: 85% [GOOD]
  → Specificity: 68% - No version numbers specified

All critical dimensions passing. Ready for optimization.
```

**Excellent quality prompt:**
```
Quality: 94% [EXCELLENT]

All dimensions passing. Prompt is well-structured and actionable.
```

### Dimension Weight Reference

Weights vary by intent. Show weight profile for transparency:

```
Weights [code-generation]: completeness(25%) > clarity(20%) = actionability(20%) > specificity(15%) > efficiency(10%) = structure(10%)
Weights [debugging]: actionability(25%) > completeness(25%) > specificity(20%) > clarity(15%) > structure(10%) > efficiency(5%)
Weights [planning]: structure(25%) > completeness(25%) > clarity(20%) > actionability(15%) > specificity(10%) > efficiency(5%)
```


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


---

## Workflow Navigation

**You are here:** Summarize (Conversation Extraction)

**Common workflows:**
- **Standard flow**: `/clavix:start` → [conversation] → `/clavix:summarize` → Use optimized prompt
- **To implementation**: `/clavix:summarize` → `/clavix:plan` → `/clavix:implement` → `/clavix:archive`
- **Standalone use**: [Any conversation] → `/clavix:summarize` → Extract and optimize

**Related commands:**
- `/clavix:start` - Begin conversational exploration (typical previous step)
- `/clavix:plan` - Generate tasks from extracted mini-PRD (next step)
- `/clavix:fast` or `/clavix:deep` - Further optimize the extracted prompt

## Example

From conversation about "analytics dashboard for sales team"...

**Original Extraction**:
```
We discussed building a dashboard for the sales team that shows analytics. They want to see revenue trends and who's performing well. It should update in real-time and help managers spot problems. We talked about using React and connecting to Salesforce.
```

**Optimized Prompt**:
```
Build a real-time sales analytics dashboard for the sales team showing revenue trends, top performers, pipeline status, and conversion rates. The dashboard should update live as deals progress, support filtering by date range/region/rep, and display key metrics prominently. Users need to quickly identify at-risk deals and celebrate wins.

Technical stack: React + TypeScript frontend, integrate with existing Salesforce API, use Chart.js for visualizations, responsive design for mobile access. Must handle 10K+ deals without performance degradation.

Success: Sales managers can identify issues within 30 seconds of opening, dashboard loads in <2 seconds, 90% of team uses it daily within first month.
```

**Improvements Applied**:
- **[Efficiency]**: Removed 8 conversational phrases, increased information density
- **[Structure]**: Organized into objective → requirements → technical → success
- **[Clarity]**: Specified exact features (filtering, metrics display) instead of vague "shows analytics"
- **[Completeness]**: Added performance requirements (10K+ deals, <2s load), success metrics (30s to identify issues, 90% adoption)
- **[Actionability]**: Converted "help managers spot problems" into specific, measurable outcome

## Troubleshooting

### Issue: Files not created or verification fails
**Cause**: Skipped file creation steps or Write tool not used
**Solution**:
- Review step 3 file creation instructions
- Ensure each file has explicit Write tool step
- Verify all files exist before continuing
- Retry the Write tool for any missing files

### Issue: Pre-extraction validation fails (missing objective/requirements)
**Cause**: Conversation didn't cover enough detail
**Solution** (inline - DO NOT extract):
- List what's missing specifically
- Ask targeted questions to fill gaps
- Only proceed to extraction after minimum viable requirements met
- Show confidence indicators for what WAS discussed

### Issue: Conversation covered multiple unrelated topics
**Cause**: Exploratory discussion without focus
**Solution**:
- Ask user which topic to extract/focus on
- Or extract all topics separately into different sections
- Mark multi-topic extraction with [MULTI-TOPIC] indicator
- Suggest breaking into separate PRDs for each topic

### Issue: Optimization doesn't significantly improve extracted prompt
**Cause**: Conversation was already well-structured and detailed
**Solution**:
- Minor improvements are normal for good conversations
- Show quality scores (should be high: >80%)
- Still provide both versions but note that original extraction was already high quality

### Issue: Low confidence indicators across all extracted elements
**Cause**: Conversation was too vague or high-level
**Solution** (inline):
- Don't just extract with [LOW] markers everywhere
- Ask follow-up questions to increase confidence
- Or inform user: "Our conversation was exploratory. I recommend `/clavix:start` to go deeper, or `/clavix:prd` for structured planning"

### Issue: Extracted prompt contradicts earlier conversation
**Cause**: Requirements evolved during conversation
**Solution**:
- Use latest/final version of requirements
- Note that requirements evolved
- Ask user to confirm which version is correct
- Suggest starting fresh with `/clavix:prd` if major contradictions exist