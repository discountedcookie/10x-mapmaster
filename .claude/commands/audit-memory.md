# Audit ConPort Memory Usage

Monitor context usage and identify items for archival or cleanup.

## Workflow Reference
- **System Pattern**: `audit-memory-workflow` (tags: audit, maintenance)
- **Detailed Steps**: ConPort Custom Data → AuditWorkflow/steps

## Execution

1. Get statistics: `get_decisions()`, `get_custom_data()`, `get_recent_activity_summary(hours_ago=168)`
2. Analyze patterns: Identify decisions unused >30d (archive), custom data unused >14d (cleanup), stale entries, redundancies
3. Generate report: Statistics + Archive candidates + Cleanup candidates + Recommendations
4. Suggest actions: Archive old decisions, delete redundant data, consolidate overlapping entries

**Thresholds**: Archive decisions >30 days unused, cleanup custom data >14 days unused
