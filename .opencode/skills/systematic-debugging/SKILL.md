---
name: systematic-debugging
description: >-
  Use for ANY bug, test failure, or unexpected behavior. Use BEFORE proposing
  fixes. Four phases: investigate, analyze, hypothesize, implement. Ensures
  understanding before attempting solutions.
---

# Systematic Debugging

Find root cause before fixing.

> **Announce:** "I'm using systematic-debugging to investigate this issue before proposing fixes."

## Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**1.1 Read Error Messages Carefully**
- Don't skip past errors
- Read complete stack traces
- Note file paths, line numbers, error codes

**1.2 Reproduce Consistently**
- Can you trigger it reliably?
- What are exact steps?
- If not reproducible → gather more data, don't guess

**1.3 Check Recent Changes**
```bash
git log --oneline -10
git diff HEAD~5
```
- What changed that could cause this?
- New dependencies? Config changes?

**1.4 Gather Evidence**

For multi-component issues, trace the data flow:
```
Component A → Component B → Component C
     ↓             ↓             ↓
  Log input    Log input    Log input
  Log output   Log output   Log output
```

Add diagnostic logging at each boundary to find WHERE it breaks.

### Phase 2: Pattern Analysis

**2.1 Find Working Examples**
- Locate similar working code in codebase
- What's different between working and broken?

**2.2 Compare Against References**
- Read relevant specs: `openspec show [capability]`
- Check documentation for expected behavior

**2.3 Identify Differences**
- List EVERY difference, however small
- Don't assume "that can't matter"

### Phase 3: Hypothesis and Testing

**3.1 Form Single Hypothesis**
State clearly:
```
I think [X] is the root cause because [Y].
Evidence: [Z]
```

**3.2 Test Minimally**
- Make SMALLEST possible change to test hypothesis
- ONE variable at a time
- Don't fix multiple things at once

**3.3 Evaluate Result**
- Hypothesis confirmed? → Phase 4
- Hypothesis rejected? → Form NEW hypothesis, return to 3.1
- If 3+ hypotheses failed → Question the architecture (see below)

### Phase 4: Implementation

**4.1 Create Failing Test**
→ REQUIRED SUB-SKILL: Load `test-tdd`
- Write test that reproduces the bug
- Verify it fails for the right reason

**4.2 Implement Fix**
- Address the ROOT CAUSE identified in Phase 2
- ONE change only
- No "while I'm here" improvements

**4.3 Verify Fix**
- New test passes
- All other tests pass
- Issue actually resolved

## Async/Queue System Investigation

When debugging async systems (pgmq, triggers, edge functions):

**1. Don't assume the queue is broken**
```sql
-- Check if queue exists and has messages
SELECT * FROM pgmq.list_queues();
SELECT * FROM pgmq.read('queue_name', 30, 10);

-- Check ARCHIVED messages (already processed!)
SELECT * FROM pgmq.a_queue_name ORDER BY archived_at DESC LIMIT 10;
```

**2. Verify triggers are attached**
```sql
SELECT tgname, tgenabled, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'schema.table'::regclass
  AND NOT tgisinternal;
```

**3. Check for race conditions**
- Multiple triggers firing for same entity?
- Concurrent executions overwriting each other?
- Look for DELETE statements that might cause data loss

**4. Trace the actual code path**
- Read the trigger function source
- Read the queue handler source
- Identify WHERE data is deleted/replaced

**Common pitfall:** "Inconsistent results" often means concurrent execution, not queue failure.

## When 3+ Fixes Fail

This indicates an architectural problem, not a bug:

```
STOP: 3+ fix attempts have failed.

This suggests the issue is architectural, not a simple bug.

Pattern observed:
- Fix 1 tried: [what]
- Fix 2 tried: [what]  
- Fix 3 tried: [what]

Each fix revealed new issues in different places.

Question: Is this pattern fundamentally sound, or should we
refactor the architecture?

Awaiting guidance before attempting more fixes.
```

## Red Flags - STOP and Reset

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"

STOP. Return to Phase 1.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, skip investigation" | Simple issues have root causes too. |
| "Emergency, no time for process" | Systematic is FASTER than thrashing. |
| "Just try this first" | First fix sets the pattern. Do it right. |
| "I'll write test after fix works" | Untested fixes don't stick. Test first. |

## REQUIRED SUB-SKILL

For implementing the fix → Load `test-tdd`

## Output Format

After investigation:

```
## Root Cause Analysis

**Symptom:** [What was observed]

**Root Cause:** [What's actually wrong]

**Evidence:** [How I know this]

**Fix:** [What should change]

**Test:** [How to verify the fix]

Proceed with fix? (Will use test-tdd skill)
```
