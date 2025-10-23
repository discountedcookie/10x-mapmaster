# Workflow: Routing Decision Tree

## Quick Reference

| Task Type | Handler | Example |
|-----------|---------|---------|
| File operations | Local | read_file, write, list_dir |
| Simple edits | Local | search_replace, small changes |
| Code inspection | Local | Serena tools (find_symbol, get_symbols_overview) |
| Safe commands | Local | npm test, npm run lint, npx supabase db reset |
| Documentation | Local | README updates, comments |
| Complex analysis | Zen MCP | Architectural decisions, design patterns |
| Security review | Zen MCP | RLS policies, auth changes |
| DB migrations | Zen MCP | Schema changes, complex queries |
| Code review | Zen MCP | Pre-commit, PR reviews |
| Refactoring | Zen MCP | Multi-file changes, algorithm optimization |
| Production ops | Ask User | Seed scripts, remote DB, deployment |
| Unclear specs | Ask User | Ambiguous requirements |

## Local Agent Handles (Default)

**Initial Triage & Planning:**
- Task decomposition
- Breaking down complex features into steps
- Creating TODO lists

**File System Operations:**
- `read_file`, `write`, `search_replace`
- `list_dir`, `glob_file_search`
- Creating, editing, deleting files

**Code Inspection with Serena:**
- `get_symbols_overview` - Understand file structure
- `find_symbol` - Read specific functions/classes
- `find_referencing_symbols` - Understand usage
- `search_for_pattern` - Find code patterns

**Simple Code Generation:**
- Boilerplate components
- Small modifications to existing code
- Adding new functions/methods
- Utility functions

**Safe Local Commands:**
- `npm run dev` - Development server
- `npm test` - Unit tests
- `npm run test:unit` - Unit tests
- `npm run test:db` - Database tests
- `npm run lint` - Linter
- `npm run type-check` - TypeScript check
- `npx supabase db reset` - Local DB reset (SAFE)
- `npm run build` - Production build

**Documentation:**
- README updates
- Code comments
- JSDoc documentation
- Memory updates (Serena patterns)

## Delegate to Zen MCP

### Trigger: Complex Analysis/Design
**When:**
- Architectural decisions affecting multiple components
- Design pattern selection
- System-wide refactoring planning
- Performance optimization strategy
- Feature planning for complex features

**Action:**
```bash
/generate_feature_plan  # Cursor command
# or
mcp_zen_analyze         # Direct MCP call
```

**Example scenarios:**
- "Should we use a store or composable for this state?"
- "How should we structure the game state machine?"
- "What's the best way to handle concurrent embedding requests?"

### Trigger: Security-Sensitive Operations
**When:**
- Changes to RLS policies
- Authentication logic changes
- Authorization checks
- Database functions with security implications
- User data access patterns

**Action:**
```bash
/analyze_security_impact  # Cursor command (BLOCKING)
```

**Example scenarios:**
- Adding new RLS policy
- Changing auth flow
- Exposing new user data in API
- Creating admin-only functions

### Trigger: Database Schema Changes
**When:**
- New migrations
- Complex query optimization
- Index strategy
- Database function creation/modification
- Schema design decisions

**Action:**
```bash
/generate_db_migration  # Cursor command
```

**Example scenarios:**
- Adding new table/column
- Creating database function
- Optimizing slow queries
- Changing relationships

### Trigger: Agentic Code Review
**When:**
- Before committing (pre-commit check)
- Before merging PR
- After significant changes
- Security/performance concerns

**Action:**
```bash
/pre_commit_check      # Pre-commit quality gates
/review_code_changes   # Full PR code review
```

**Example scenarios:**
- Feature complete, ready to commit
- PR created, needs review
- Refactoring done, validate changes

### Trigger: Complex Refactoring
**When:**
- Multi-file changes
- Algorithm optimization
- Component restructuring
- Breaking API changes
- Migration from one pattern to another

**Action:**
```bash
/refactor_component  # Cursor command
```

**Example scenarios:**
- Extracting shared logic into composable
- Optimizing vector similarity algorithm
- Restructuring component hierarchy
- Renaming widely-used functions

## Ask User First

### Trigger: Production Database Operations
**When:**
- Any `--remote` flag usage
- `supabase db reset --remote`
- Seed scripts (`npm run seed:places`, `npm run seed:questions`)
- Manual data changes in production
- Schema changes on live database

**Why:**
- Requires environment variables
- Irreversible operations
- User has production credentials
- Agent must NOT have production access

### Trigger: Deployment to Production
**When:**
- Deploying to hosting
- DNS changes
- Production environment variables
- CI/CD configuration changes

**Why:**
- Affects live users
- Requires production credentials
- User should control deployment timing

### Trigger: Breaking Changes
**When:**
- Changes to public API
- Database schema changes that lose data
- Removing features
- Changing auth flow

**Why:**
- May affect existing users
- Needs user approval for trade-offs
- Requires communication plan

### Trigger: Unclear Requirements
**When:**
- Ambiguous specifications
- Multiple valid implementation approaches
- User preference needed (UI/UX decisions)
- Trade-off decisions

**Why:**
- Better to clarify than guess wrong
- User knows intent better than agent
- Saves rework from wrong assumptions

## Decision Tree Examples

### Example 1: Adding a New Component
```
Task: Add a ConfidenceBadge component

Step 1: Local agent creates component
Step 2: Local agent adds to component index
Step 3: Local agent uses component in parent
Step 4: Local agent runs lint + type-check
Step 5: /pre_commit_check (Zen MCP review)
```

### Example 2: Database Schema Change
```
Task: Add question_category column to questions table

Step 1: Ask user if production data exists
Step 2: /generate_db_migration (Zen MCP)
Step 3: Local agent tests with npx supabase db reset
Step 4: Local agent regenerates types: npm run supabase:types
Step 5: Local agent updates code to use new column
Step 6: /analyze_security_impact (Zen MCP if RLS affected)
Step 7: /review_code_changes (Zen MCP)
```

### Example 3: Seed Data Issue
```
Task: Places missing embeddings after db reset

Step 1: Local agent identifies problem (NULL embeddings)
Step 2: Local agent resets DB: npx supabase db reset
Step 3: Ask user to run: npm run seed:places && npm run seed:questions
Step 4: Local agent verifies with Supabase MCP queries
```

## Cursor Commands Reference

Available in `.claude/commands/`:
- `generate_feature_plan` - Complex feature planning
- `pre_commit_check` - Pre-commit quality gates (BLOCKING)
- `review_code_changes` - Full PR code review
- `analyze_security_impact` - Security review (BLOCKING)
- `generate_db_migration` - Safe migration generation
- `refactor_component` - Component optimization

**Usage:** Type `/command-name` in Cursor

## When in Doubt

**Default to local agent** - Most tasks can be handled locally  
**Use Zen for complexity** - When analysis/review adds value  
**Ask user for production** - Never touch production without permission