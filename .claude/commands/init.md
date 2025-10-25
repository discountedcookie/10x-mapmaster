# Initialize Project Context

## Purpose
Load minimal critical project context from ConPort and prepare for work.

## Steps

1. **Query ConPort for Critical Context**
   - Get current git branch from Active Context
   - Get project architecture from Product Context
   - Get Supabase branch mapping from Custom Category
   - Load only critical tier unless task explicitly requires more

2. **Announce Readiness**
   - Display: "Ready! What are we working on today?"
   - Show: Current branch + task focus
   - Include: Any blocking items from Active Context

3. **Load Only If Needed**
   - Get Decisions only if task is architectural
   - Load workflow patterns only if building new features
   - Decisions/patterns available via memory but not auto-loaded

## Outcome
Agent starts with minimal context (~500 tokens), ready to pull additional context as needed.

## Related Commands
- `/audit-memory` - Check ConPort usage
- `/handoff` - Prepare for next agent
