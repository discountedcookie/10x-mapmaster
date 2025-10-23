# Workflow: Serena Patterns

## Memory Update Patterns

### When to Overwrite vs Append

**Overwrite (replace entire memory):**
- Current state has changed significantly
- Previous information is outdated
- Milestone completed, start new phase
- Design decision reversed

**Example:**
```typescript
mcp_serena_write_memory({
  memory_name: "02-current-state",
  content: "# Current State - NEW MILESTONE\n\n..." // Full new content
})
```

**Append (add to existing content):**
- Adding new known issues
- Adding new troubleshooting solutions
- Documenting additional patterns
- Recording new design decisions

**Example:**
```typescript
// Read existing content first
const existing = mcp_serena_read_memory("diagnostics-known-issues")

// Append new section
mcp_serena_write_memory({
  memory_name: "diagnostics-known-issues",
  content: existing + "\n\n## New Issue\n\n..."
})
```

### Memory Naming Conventions

**Use lowercase with dashes:**
- ✅ `00-memory-index`
- ✅ `workflow-database`
- ✅ `game-complete-flow`
- ❌ `01_Quick_Start` (underscores, title case)
- ❌ `workflowDatabase` (camelCase)

**Use numbered prefixes for priority:**
- `00-` - Index/guide
- `01-` - Quick start
- `02-` - Current state
- No prefix for regular files

**Use descriptive names:**
- `workflow-database` not `db-workflow`
- `game-complete-flow` not `game-flow`
- `tech-stack` not `technology`

### When to Create New Memories

**Create new memory when:**
- New major feature added (game mechanics, architecture decision)
- New workflow pattern emerges (testing, deployment)
- Significant troubleshooting knowledge gained
- New system integration (external API, service)

**Don't create new memory for:**
- Minor bug fixes (add to diagnostics-solutions)
- Small code changes (update existing memory)
- Temporary workarounds (comment in code)
- Task-specific information (not relevant to future sessions)

### When to Delete Memories

**Delete memory when:**
- Information contradicted by user
- Feature completely removed
- Workflow replaced with better approach
- Duplicate information exists

**Process:**
```typescript
mcp_serena_delete_memory({
  memory_file_name: "outdated-memory"
})
```

**Better than deleting:** Update to reflect current state

## Think About Tools

### `think_about_collected_information`

**Always call after:**
- Multiple `find_symbol` calls
- Multiple `find_referencing_symbols` calls
- Multiple `search_for_pattern` calls
- Multiple `read_file` calls
- Any non-trivial search sequence

**Purpose:**
- Reflect on whether you have sufficient information
- Decide if you need more searching
- Avoid over-searching or under-searching

**Example:**
```typescript
// After searching
find_symbol({ name_path: "GameStore", ... })
find_referencing_symbols({ name_path: "topCandidates", ... })
read_file({ target_file: "src/stores/game.ts" })

// Think about it
think_about_collected_information()

// Decision: Do I need more info or can I proceed?
```

### `think_about_task_adherence`

**Always call before:**
- Inserting code
- Replacing code
- Deleting code
- Making schema changes
- Any code modification

**Especially important:**
- Long conversations with lots of back-and-forth
- After multiple clarifications
- When task evolved from original request

**Purpose:**
- Verify you're still on track
- Check you understood requirements correctly
- Avoid implementing wrong solution

**Example:**
```typescript
// Before editing
think_about_task_adherence()

// Decision: Am I solving the right problem?
// Then proceed with edits
mcp_serena_replace_symbol_body({ ... })
```

### `think_about_whether_you_are_done`

**Always call when:**
- You believe task is complete
- All TODOs marked complete
- Tests are passing
- No obvious next steps

**Purpose:**
- Verify completeness
- Check for missed requirements
- Confirm with yourself before telling user

**Example:**
```typescript
// After completing all work
think_about_whether_you_are_done()

// Then summarize changes
mcp_serena_summarize_changes()
```

## Serena Tool Usage Patterns

### Start with Overview, Then Drill Down

**Pattern:**
```typescript
// 1. Get high-level overview
get_symbols_overview({ relative_path: "src/stores/game.ts" })

// 2. Find specific symbol
find_symbol({
  name_path: "GameStore",
  relative_path: "src/stores/game.ts",
  depth: 1,
  include_body: false
})

// 3. Read only needed methods
find_symbol({
  name_path: "GameStore/fetchCandidates",
  relative_path: "src/stores/game.ts",
  include_body: true
})

// 4. Think about collected info
think_about_collected_information()
```

### Avoid Reading Entire Files

**Bad:**
```typescript
read_file({ target_file: "src/stores/game.ts" }) // 500 lines
```

**Good:**
```typescript
get_symbols_overview({ relative_path: "src/stores/game.ts" })
find_symbol({ name_path: "topCandidates", include_body: true })
```

**Exception:** Small files (<100 lines), config files, types files

### Use Substring Matching for Exploration

**When you don't know exact name:**
```typescript
find_symbol({
  name_path: "fetch",  // Finds fetchCandidates, fetchPlaces, etc.
  substring_matching: true,
  relative_path: "src/stores/"
})
```

### Restrict Search Scope

**Use `relative_path` to narrow down:**
```typescript
// Good - focused search
find_symbol({
  name_path: "PlaceCard",
  relative_path: "src/components/"
})

// Bad - searches entire codebase
find_symbol({
  name_path: "PlaceCard",
  relative_path: ""
})
```

## Memory Reading Strategy

### First-Time in Session
1. Read `01-quick-start` - Get oriented
2. Read `02-current-state` - Understand latest work
3. Read task-specific memories only

### Returning in Same Session
- Don't re-read memories you already read
- Only read new memories relevant to current task

### Task-Specific Reading
| Task | Read |
|------|------|
| Database work | workflow-database, workflow-safety-rules |
| Frontend work | tech-stack, design-architecture |
| Bug fixing | diagnostics-known-issues, diagnostics-solutions |
| Testing | workflow-testing |

## Memory Update Checklist

**Before creating memory:**
- [ ] Is this information relevant to future sessions?
- [ ] Does this belong in an existing memory?
- [ ] Is the name descriptive and follows conventions?
- [ ] Is the content well-organized?

**Before updating memory:**
- [ ] Should I overwrite or append?
- [ ] Is previous information still accurate?
- [ ] Did user contradict existing information? (delete or update)

**Before deleting memory:**
- [ ] Is this truly obsolete?
- [ ] Can I update it instead?
- [ ] Is there duplicate information elsewhere?

## Common Mistakes to Avoid

**Don't:**
- ❌ Read entire files unnecessarily
- ❌ Search without using `relative_path`
- ❌ Re-read memories in same session
- ❌ Create memories for task-specific info
- ❌ Update memories too frequently (batch updates)
- ❌ Forget to call `think_about_*` tools

**Do:**
- ✅ Use symbolic tools (get_symbols_overview, find_symbol)
- ✅ Restrict search scope with `relative_path`
- ✅ Only read memories relevant to current task
- ✅ Consolidate related information
- ✅ Update memories when information changes
- ✅ Call `think_about_*` tools at appropriate times