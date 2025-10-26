# Initialize Project Context

Execute the init workflow stored in ConPort to load minimal critical context and prepare for work.

## Workflow Reference
- **System Pattern**: `init-workflow` (tags: init, workflow, critical)
- **Detailed Steps**: ConPort Custom Data → InitWorkflow/steps

## Execution

1. Load Serena patterns: `get_system_patterns(tags=["serena","critical"])`
2. Load critical context: `get_active_context()`, `get_product_context()`, `get_custom_data(category="SupabaseBranches")`
3. Announce: "Ready! What are we working on today?" + branch + task + blockers
4. Defer: Load decisions/patterns only when task requires

**Goal**: Start with ~500 tokens, pull additional context as needed.
