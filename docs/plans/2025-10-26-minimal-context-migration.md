# Minimal Context Workflow Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate from overloaded context (Serena + Memory MCP) to minimal ConPort-based workflow

**Architecture:** Hierarchical memory with Context Portal, git worktrees for agents, Supabase branching for databases

**Tech Stack:** Context Portal MCP, Supabase MCP, SQLite, Claude commands

---

## Pre-Migration Setup (User Completes)

- [ ] Install Context Portal MCP server
- [ ] Install Supabase MCP with production credentials
- [ ] Verify both MCPs appear in Claude settings

---

## Task 1: Memory Audit & Backup

**Files:**
- Read: `.serena/*`
- Read: Memory MCP graph via tool
- Create: `docs/memory-audit.md`

**Step 1: List all Serena memory files**

```bash
find .serena -type f -name "*.md" | head -20
```

Expected: List of memory files with timestamps

**Step 2: Check Memory MCP entity counts**

Use mcp__memory__read_graph tool to get full graph.
Count entities by type (person, project, concept, etc.)

**Step 3: Document what's actually valuable**

Create `docs/memory-audit.md`:

```markdown
# Memory Audit - 2025-10-26

## Serena Memories to Keep
- project_structure.md - Contains architecture overview
- database_schema.md - Current schema documentation

## Memory MCP Entities to Migrate
- Entity: "10x-mapmaster" (type: project) - Core project info
- Entity: "confidence_scores" (type: feature) - Current work

## To Delete
- All other Serena memories (outdated/redundant)
- Memory MCP relationships older than 30 days
```

**Step 4: Export Memory MCP to backup**

```bash
mkdir -p backups
# Use mcp__memory__read_graph and save output
echo "[Memory graph JSON]" > backups/memory-mcp-backup.json
```

**Step 5: Commit audit**

```bash
git add docs/memory-audit.md
git commit -m "docs: complete memory audit before migration"
```

---

## Task 2: ConPort Initialization

**Files:**
- Create: `context_portal/context.db` (auto-created)
- Create: `.claude/commands/init-conport.md`

**Step 1: Initialize ConPort database**

```bash
# ConPort will auto-create on first use
mkdir -p context_portal
```

**Step 2: Create temporary init command**

Create `.claude/commands/init-conport.md`:

```markdown
Initialize ConPort with minimal project context:

1. Create Product Context entry for project basics
2. Add current git branch to Active Context
3. Set up workspace config in Custom Category
```

**Step 3: Add ConPort to .gitignore if needed**

```bash
echo "context_portal/*.db-journal" >> .gitignore
echo "context_portal/*.db-wal" >> .gitignore
```

**Step 4: Test ConPort connection**

Run init-conport command in Claude to verify ConPort works.

**Step 5: Commit ConPort setup**

```bash
git add .claude/commands/init-conport.md .gitignore
git commit -m "feat: initialize ConPort for context management"
```

---

## Task 3: Migrate Essential Context to ConPort

**Files:**
- Read: `docs/memory-audit.md`
- Modify: ConPort database via tools

**Step 1: Create Product Context for architecture**

Add to ConPort Product Context:
```
Title: "10x-mapmaster Architecture"
Content: "Event-driven Next.js app with Supabase backend. Uses confidence scoring for map candidate ranking. Main tables: candidates, confidence_scores, user_interactions."
```

**Step 2: Create Active Context for current work**

Add to ConPort Active Context:
```
Title: "Confidence Score Refactoring"
Content: "Migrating get_candidates function to use new confidence scoring algorithm. Branch: main. Status: In progress."
```

**Step 3: Add Decision records for key patterns**

Add to ConPort Decisions:
```
Title: "Use pgvector for semantic search"
Content: "Decision: Use Supabase-hosted pgvector for all vector operations. Rationale: Local pgvector not available. Implementation: All vector ops through Supabase MCP."
```

**Step 4: Create Custom Category for Supabase branches**

Add to ConPort Custom Category "supabase-branches":
```
{
  "main": "production",
  "feature-auth": "branch-abc123",
  "test-auth": "branch-def456"
}
```

**Step 5: Verify migration**

Query ConPort to confirm all essential context migrated.

---

## Task 4: Create Minimal Claude Commands

**Files:**
- Create: `.claude/commands/init.md`
- Create: `.claude/commands/audit-memory.md`
- Create: `.claude/commands/handoff.md`
- Delete: `.claude/commands/init-conport.md`

**Step 1: Create main init command**

Create `.claude/commands/init.md`:

```markdown
Query ConPort for minimal context then announce readiness:

1. Get current git branch from ConPort Active Context
2. Get Supabase branch mapping from Custom Category
3. Load only if task requires it
4. Say: "Ready! What are we working on today?"
```

**Step 2: Create memory audit command**

Create `.claude/commands/audit-memory.md`:

```markdown
Check context usage:

1. Count ConPort entries by category
2. List entries accessed >30 days ago
3. Show total context size
4. Suggest items to archive
```

**Step 3: Create handoff command**

Create `.claude/commands/handoff.md`:

```markdown
Prepare context for next agent:

1. Write current progress to ConPort Active Context
2. Document any decisions made
3. Clear working memory
4. Output: "Handoff ready in ConPort"
```

**Step 4: Remove temporary command**

```bash
rm .claude/commands/init-conport.md
```

**Step 5: Commit commands**

```bash
git add .claude/commands/*.md
git commit -m "feat: add minimal Claude commands for ConPort workflow"
```

---

## Task 5: Clean Up Old Memory Systems

**Files:**
- Delete: `.serena/` directory
- Modify: `.mcp.json` to remove Memory MCP
- Create: `docs/migration-complete.md`

**Step 1: Archive Serena memories**

```bash
tar -czf backups/serena-memories.tar.gz .serena/
rm -rf .serena/
```

**Step 2: Remove Memory MCP from config**

Edit `.mcp.json` to remove Memory MCP server configuration.
Keep only ConPort and Supabase MCP.

**Step 3: Clean up any remaining memory references**

```bash
grep -r "serena\|memory_mcp" . --exclude-dir=backups
# Fix any remaining references found
```

**Step 4: Document migration completion**

Create `docs/migration-complete.md`:

```markdown
# Migration to Minimal Context Complete

## What Changed
- Removed: Serena memories, Memory MCP
- Added: Context Portal for structured context
- Result: <1000 token initial context

## New Workflow
1. Agents start with empty context
2. Run init.md to load minimal critical tier
3. Skills pull from ConPort as needed
4. Silent operation with ConPort progress tracking

## Backup Location
- `backups/serena-memories.tar.gz`
- `backups/memory-mcp-backup.json`
```

**Step 5: Final commit**

```bash
git add -A
git commit -m "feat: complete migration to minimal context workflow"
```

---

## Task 6: Test New Workflow

**Files:**
- Test: New Claude session
- Create: `test-results.md`

**Step 1: Start fresh Claude session**

Close current session, start new one in project.

**Step 2: Verify minimal initial context**

Check that initial context is <1000 tokens.
Should see only: "Ready! What are we working on today?"

**Step 3: Test ConPort queries**

Ask agent to describe project architecture.
Should pull from ConPort Product Context.

**Step 4: Test silent operation**

Give agent a small task.
Verify progress written to ConPort, not console.

**Step 5: Document test results**

Create `test-results.md`:

```markdown
# Minimal Context Workflow Test

## Initial Context Size
- Before: [previous size]
- After: <1000 tokens ✓

## ConPort Integration
- Queries working ✓
- Context retrieval fast ✓

## Silent Operation
- Console output minimal ✓
- Progress in ConPort ✓
```

---

## Task 7: Set Up First Worktree

**Files:**
- Create: `worktrees/feature-example/`
- Create: `worktrees/README.md`

**Step 1: Create first feature worktree**

```bash
git worktree add worktrees/feature-example -b feature-example
```

**Step 2: Test worktree with ConPort**

```bash
cd worktrees/feature-example
# Start Claude session here
# Verify it reads worktree config from ConPort
```

**Step 3: Create worktree documentation**

Create `worktrees/README.md`:

```markdown
# Worktree Structure

## Naming Convention
- `feature-<name>` - Implementation work
- `test-<name>` - Test development
- `review-<name>` - Code review
- `fix-<name>` - Bug fixes

## ConPort Integration
Each worktree automatically:
1. Maps to Supabase branch
2. Gets role-specific context
3. Writes progress to ConPort
```

**Step 4: Add Supabase branch mapping**

Update ConPort Custom Category with worktree mapping.

**Step 5: Commit worktree setup**

```bash
git add worktrees/README.md
git commit -m "feat: set up worktree structure for multi-agent workflow"
```

---

## Success Criteria

- [ ] Initial context <1000 tokens
- [ ] ConPort queries working
- [ ] Serena memories deleted
- [ ] Memory MCP removed
- [ ] Claude commands minimal
- [ ] Worktree structure ready
- [ ] Silent agent operation verified

## Next Steps

After migration complete:
1. Test parallel agent work in separate worktrees
2. Verify Supabase branch isolation
3. Run full feature development cycle
4. Monitor context size over time