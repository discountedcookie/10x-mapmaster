# Prepare Handoff to Next Agent

## Purpose
Document work progress and context for the next agent to pick up seamlessly.

## Steps

1. **Write Current Progress to Active Context**
   - Summarize what was completed this session
   - List files modified or created
   - Document any blockers encountered
   - Update "next_steps" for continuity
   - Clear "context_migration" if applicable (migration complete)

2. **Document Any Decisions Made**
   - If architectural decisions made this session: log to Decisions
   - Include rationale and implementation details
   - Tag appropriately for later search
   - Link to any related code changes

3. **Clear Working Memory**
   - Remove any temporary custom data entries
   - Archive interim design notes if needed
   - Keep only structural/architectural content

4. **Output Confirmation**
   - Show: "Handoff ready in ConPort"
   - Display: Summary of what was logged
   - Suggest: Next agent should run `/init` command

## Handoff Checklist

- [ ] Active Context updated with session summary
- [ ] Recent changes documented
- [ ] Blockers and next steps clear
- [ ] New decisions logged if applicable
- [ ] Temporary data cleared
- [ ] Confirmation displayed

## Related Commands
- `/init` - Load context for next session
- `/audit-memory` - Check for stale entries before handoff
