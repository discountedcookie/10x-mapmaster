# Git Worktrees for Parallel Agent Work

This directory contains git worktrees for isolated, parallel development work. Each worktree represents a separate feature, fix, or testing branch with its own copy of the repository.

## Naming Conventions

Use consistent naming patterns to make worktrees self-documenting:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `feature-*` | New feature development | `feature-confidence-scoring` |
| `fix-*` | Bug fixes | `fix-naN-bounds` |
| `test-*` | Test suite additions | `test-database-integration` |
| `refactor-*` | Code refactoring | `refactor-map-game` |
| `docs-*` | Documentation work | `docs-api-guide` |

## Workflow

### Creating a New Worktree

```bash
# From project root (NOT from worktree)
git worktree add .worktrees/feature-name -b feature/feature-name
cd .worktrees/feature-name
```

### Working in a Worktree

```bash
# Each worktree is isolated with its own git branch
cd .worktrees/feature-name

# Check status
git status
git log

# Make changes, commit normally
git add .
git commit -m "feature: description"

# When ready, push to origin
git push -u origin feature/feature-name
```

### Merging Back to Main

From the worktree OR main directory:

```bash
# Option 1: Merge PR (recommended)
gh pr create --base main

# Option 2: Manual merge from main
cd /Users/ciaastek/Projects/Sirocco/10x-mapmaster  # Back to main
git merge feature/feature-name
```

### Cleaning Up Worktrees

```bash
# After merge, delete the worktree
git worktree remove .worktrees/feature-name

# Or use full path
git worktree remove /Users/ciaastek/Projects/Sirocco/10x-mapmaster/.worktrees/feature-name
```

## ConPort Integration

Each worktree inherits access to the **shared ConPort database** at `context_portal/context.db`.

### Agent Workflow in Worktree

```bash
cd .worktrees/feature-name

# 1. Start session - load minimal context
/init

# 2. Work on task using ConPort for progress tracking
# - Decisions logged to shared ConPort
# - Progress tracked in Active Context
# - Custom Data organized by category

# 3. End session - prepare for handoff
/handoff

# 4. Next agent in same or different worktree
/init  # Loads shared ConPort context
```

### Worktree-Specific Context

While ConPort is shared, each agent can track worktree-specific state:

```
ConPort Custom Data Category: "worktree-context"
{
  "feature-confidence-scoring": {
    "agent": "agent-name",
    "session_start": "2025-10-26T20:00:00Z",
    "current_task": "Implement percentile normalization",
    "blockers": []
  }
}
```

## Supabase Branch Integration

Each worktree can have an associated Supabase database branch:

| Worktree | Git Branch | Supabase Branch | Purpose |
|----------|-----------|-----------------|---------|
| (main) | main | prod | Production |
| feature-confidence-scoring | feature/confidence-scoring | branch_abc123 | Feature isolation |
| fix-naN-bounds | fix/naN-bounds | branch_def456 | Bug fix testing |

### Creating Supabase Branch

```bash
# From worktree after creating git branch
supabase branches create --parent prod feature-confidence-scoring

# Update ConPort with mapping
# (Run /init, then update ConPort with new branch info)
```

## Important Notes

⚠️ **Shared State:**
- Main repository at root level: `/Users/ciaastek/Projects/Sirocco/10x-mapmaster/`
- ConPort database: `context_portal/context.db` (shared across all worktrees)
- Git remotes: Shared (all worktrees push/pull from same origin)

✅ **Isolated State:**
- Working directory: Each worktree has its own files
- Git branch: Each worktree on separate branch
- Node modules: Can be separate (`node_modules/` not shared)
- Environment: Each worktree can have `.env.local` if needed

## Examples

### Example 1: Quick Feature Work

```bash
# Create worktree
git worktree add .worktrees/feature-quick-fix -b feature/quick-fix
cd .worktrees/feature-quick-fix

# Load context
/init

# Make changes
echo "// fix" > src/fix.ts
git add .
git commit -m "fix: quick issue"
git push -u origin feature/quick-fix

# Ready to PR
gh pr create --base main

# Back in main, merge
cd ..
git merge feature/quick-fix
git worktree remove .worktrees/feature-quick-fix
```

### Example 2: Parallel Development

**Two agents work simultaneously:**

```
Agent A: .worktrees/feature-confidence-scoring
- Working on percentile normalization
- ConPort shared, Active Context updated
- Supabase branch: prod-feature-confidence-001

Agent B: .worktrees/test-database-integration
- Writing integration tests
- Reads decisions from Agent A's work
- Supabase branch: prod-test-integration

Both push to origin, Agent A merges first, Agent B rebases
```

## Troubleshooting

**Q: Worktree is stale, how do I sync with main?**

```bash
cd .worktrees/feature-name
git fetch origin
git rebase origin/main
```

**Q: ConPort database locked when switching worktrees?**

ConPort uses SQLite which supports concurrent readers. If you hit a lock:
```bash
# Wait a moment, then retry
# ConPort lock timeouts are short (~2 seconds)
```

**Q: How do I see all worktrees?**

```bash
git worktree list

# Output:
# /path/to/main                               abc123 [main]
# /path/to/.worktrees/feature-name            def456 [feature/name]
```

**Q: Delete worktree permanently?**

```bash
git worktree remove .worktrees/feature-name
# OR with force
git worktree remove --force .worktrees/feature-name
```

## ConPort Worktree Mapping

To track worktree-to-Supabase mappings in ConPort:

```bash
# In ConPort Custom Data category "supabase-branches"
# Add entries like:
{
  "feature-confidence-scoring": {
    "branch_id": "branch_abc123",
    "environment": "staging",
    "status": "active",
    "agent": "agent-name"
  }
}
```

See `docs/migration-complete.md` for how to update ConPort manually.
