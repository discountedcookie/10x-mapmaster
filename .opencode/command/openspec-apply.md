---
agent: build
description: Implement an approved OpenSpec change
subtask: true
---

Load the `openspec-apply` and `test-tdd` skills, then implement:

<ChangeId>
$ARGUMENTS
</ChangeId>

**Change details:**
!`openspec show $1 2>/dev/null || echo "Run 'openspec list' to see available changes"`
