# Audit ConPort Memory Usage

## Purpose
Monitor context usage and identify items for archival or cleanup.

## Steps

1. **Get ConPort Statistics**
   - Query Decisions count by tag
   - Query Custom Data count by category
   - Get recent activity (last 7 days)
   - Calculate total ConPort size

2. **Analyze Usage Patterns**
   - List decisions accessed >30 days ago (archive candidates)
   - List custom data entries unused >14 days (cleanup candidates)
   - Check Active Context for stale entries
   - Identify redundant entries

3. **Generate Report**
   ```
   ConPort Audit Report - [date]

   Statistics:
   - Decisions: N (tags: ...)
   - Custom Data: N (categories: ...)
   - Recent Activity: N entries

   Archive Candidates (unused >30 days):
   - [Decision: summary]

   Cleanup Candidates (unused >14 days):
   - [Custom Data: category/key]

   Recommendations:
   - Archive: [items]
   - Delete: [items]
   ```

4. **Suggest Actions**
   - Archive old decisions to external storage
   - Delete redundant custom data
   - Consolidate overlapping entries

## Related Commands
- `/init` - Load critical context
- `/handoff` - Prepare for next agent
