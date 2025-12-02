---
agent: build
description: Archive a completed OpenSpec change
---

Archive the following change:

<ChangeId>
$ARGUMENTS
</ChangeId>

**Steps:**
1. If no change ID provided, run `openspec list` and ask which to archive
2. Validate: `openspec show <id>` - confirm all tasks complete
3. Archive: `openspec archive <id> --yes`
4. Verify: `openspec validate --strict`

**Current changes:**
!`openspec list`
