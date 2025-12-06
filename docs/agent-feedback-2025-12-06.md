# Agent Feedback - Learning System Tests (2025-12-06)

Subagents were asked to reflect on their experience after completing tests on the learning system.

---

## Agent 1: Session Approval Triggers Learning (supabase-expert)

### 1. **Initial Context - INSUFFICIENT**

- ✅ Had schema docs and code structure
- ❌ **No runtime state snapshot** - I had to blindly query to find test data
- ❌ **No guidance on what sessions exist** - I spent 3-4 queries finding pending sessions when you could have said "use session ID X"
- Suggestion: **Provide current DB state at task start** - pending sessions, sample data, recent activity

### 2. **Instructions - CLEAR but I DIDN'T FOLLOW THEM**

- Your 5-step plan was crystal clear: find → check before → approve → check queue → check after
- But I jumped around investigating instead of executing sequentially
- I should have used `skills_executing_tasks` and been rigorous about "do step 1, verify, checkpoint, move to step 2"
- **My fault here** - the instructions were good, I just got curious and wandered

### 3. **Available Tools - ADEQUATE but AWKWARD**

- postgres\_\* tools worked great
- ❌ **Can't use `ls`/`find`** - forced me to use `glob`/`list` for simple directory browsing
  - This added friction for basic navigation
  - Every directory listing became a function call instead of instant feedback
- ✅ **bash for grep was helpful** when it worked
- **Suggestion:** Relax bash restrictions for safe commands like `ls`, `find -type f`, or at least `tree`

### 4. **Available Skills - I MISSED THE OBVIOUS ONE**

- 🔴 **I didn't load `skills_gameplay_sql`** - this tool is PERFECT for testing game mechanics
  - It's explicitly designed to "test game mechanics via SQL"
  - Instead I fumbled through ad-hoc queries
- 🔴 **I didn't load `skills_systematic_debugging`** - even though I was investigating "unexpected behavior"
  - Could have helped organize my investigation better
- **Suggestion:** Make skills more discoverable. Maybe a quick prompt like "This looks like a test task - load skills_testing?" or "Found a complex system - consider skills_systematic_debugging?"

### 5. **What Would Have Made This MUCH Easier**

| What                         | Why                         | How                                                          |
| ---------------------------- | --------------------------- | ------------------------------------------------------------ |
| **DB snapshot**              | No hunting for test data    | `SELECT COUNT(*) WHERE pending_review=TRUE` in task preamble |
| **Sequential task tracking** | Would've kept me on rails   | Use `skills_executing_tasks` from the start                  |
| **Proactive skill loading**  | Matching tools to task type | "This is a database test → load skills_gameplay_sql"         |
| **Better bash access**       | Friction-free exploration   | Allow `ls`, `find`, `tree` - they're read-only               |
| **Sample session IDs**       | Skip the scavenger hunt     | "Here are 3 pending sessions to test with: [IDs]"            |

### 6. **The Good**

- ✅ postgres_execute_sql is genuinely powerful
- ✅ I successfully avoided the temptation to "fix" things and reported honestly
- ✅ The report was comprehensive and organized
- ✅ Tool parallelization worked well for multi-query batches

---

## Agent 2: Sequential Learning on Bulk Approval (supabase-expert)

### What Went Well

- **Tools**: postgres\_\* functions were excellent for schema discovery
- **SQL testing**: Could write and execute tests directly against real DB
- **Fearless exploration**: No penalties for investigating wrong paths

### What Was Harder Than It Should Have Been

**1. Initial Context Gap**
I didn't know pgmq was the queue system until I stumbled on `postgres_list_schemas`. Should have started with:

- "The learning queue uses pgmq (PostgreSQL Message Queue)"
- Key tables: `pgmq.q_trait_extraction`, `pgmq.a_trait_extraction`
- Trigger: `on_session_approval_regenerate_traits_trigger` → `enqueue_trait_extraction()`

**2. Test Data Problem**

- Instructions said "find multiple pending sessions" but there weren't any
- Had to create test sessions from scratch
- Unclear if test sessions needed specific state (was_correct=TRUE? place_id required?)

**3. Race Condition Definition**

- Started testing without clear definition: Was I looking for duplicates? Deadlocks? Lost messages? Over-processing?
- Took me a while to understand pgmq's visibility timeout was the core safety mechanism

**4. Artifact vs Bug Confusion**

- Early stress test showed "5 duplicate messages"
- Spent time investigating before realizing they were from earlier test runs, not race conditions
- Should have been more systematic: use transaction isolation to distinguish test runs

### What Would Have Made This 10x Easier

1. **5-minute architecture doc**

   ```
   Learning happens asynchronously via pgmq.
   When session approved → trigger enqueues message → edge function processes.
   Race conditions possible in: trigger firing, message deduplication,
   concurrent processing. Use visibility timeout + read_ct to verify.
   ```

2. **Pre-written test harness**
   - Template for "create N test sessions, approve atomically, check queue state"
   - Not full implementation, just structure

3. **Clearer success criteria**
   - "✓ No duplicate messages from single transaction"
   - "✓ Visibility timeout prevents concurrent reads"
   - "✓ No orphaned messages (read_ct > N or age > threshold)"

4. **Schema quick reference**
   - What each column means (read_ct, vt, enqueued_at)
   - Why it matters for race conditions

### About My Tools & Skills

**Tools feedback:**

- Would have benefited from: `postgres_run_sql_batch()` to execute multiple test files sequentially without manually concatenating
- Read/glob/grep/postgres\_\* were genuinely excellent

**Skills I didn't use:**

- Didn't load `skills_systematic_debugging` (should have!)
- Didn't load any thinking tools early
- Could have used something like `skills_investigation` with a guided discovery process

**What's missing:**

- A "structured investigation" workflow for "explore + test + verify" type tasks
- Doesn't need to be complex, just: form hypothesis → design test → execute → analyze

### The Real Issue

I was efficient but not _guided_. I knew the task ("check queue"), but not:

- The domain (didn't know pgmq existed initially)
- Success definition (what counts as race condition?)
- Systematic method (explored somewhat randomly before organizing)

This is like asking someone to "verify the login system works" without telling them if they should test SQL injection, session management, or both.

---

## Agent 3: New Place Appears on Map After Learning (player)

### What Went Well

- The browser tools worked reliably for navigation, clicking, and snapshots
- I could see the game UI and understand the flow
- The game itself appears functional (questions loading, map updating)

### Critical Issues

**1. Insufficient Initial Context**

- I didn't know if the game required authentication
- No guidance on what "learning traits" means or how long it takes
- Unclear if I should use the API tools (`game_start`, `game_turn`, `game_submit`) or browser automation
- The instructions said "Do NOT fix anything. Just report what you observe" but didn't clarify: should I use the game API or browser UI?

**2. Ambiguous Task Scope**

- "Play through the game" - how many questions? Until it guesses? Until max turns?
- "Let it guess wrong" - should I deliberately answer incorrectly, or just let the game fail naturally?
- "Submit the correct place via the UI" - but I don't know the actual place name for my fictional description
- "Wait for trait extraction to complete" - how do I know when it's done? What should I observe?

**3. Tool Confusion**

- I have `game_start`, `game_turn`, `game_submit` functions that seem purpose-built for this
- But I also have full browser automation tools
- No guidance on which to use when

**4. Missing Information**

- What does "learning traits" actually do in the system?
- How do I verify a new place was added to the database?
- Should I check the database directly, or only observe UI changes?
- What's the expected timeline for trait extraction?

### What Would Help

1. **Clear tool selection guidance**: "Use the game API tools for this test, not browser automation" (or vice versa)
2. **Concrete success criteria**: "New place appears as a marker on the map within 30 seconds" or "Check database table X for the new entry"
3. **Fictional place handling**: Either provide a real place to use, or explain how to verify a fictional one was added
4. **State management**: Clarify if I should start fresh or if prior session state is expected
5. **Observation checklist**: Specific things to look for (console errors, network requests, database state)

### My Recommendation

For future gameplay tests, provide:

- **Which tools to use** (API vs browser)
- **Exact success criteria** (what proves it worked)
- **Real test data** (actual place names/coordinates)
- **Observation points** (where to look for evidence)

I was ready to continue but got stuck on ambiguity rather than technical limitations.

---

## Agent 4: Existing Places Get Updated Traits (supabase-expert)

### What Went Well

1. **Clear instructions** - "test, don't fix, report honest state" was unambiguous
2. **Excellent schema tools** - postgres\_\* functions let me trace the full flow systematically
3. **Good documentation** - AGENTS.md and schema comments explained the architecture
4. **Disciplined approach** - I didn't speculate; I verified each step with actual queries

### What Was Frustrating

**1. Missing Context About Local Environment**

- I spent ~20 minutes discovering that `call_llm_api()` tries to call **external Supabase edge functions**
- No documentation about: "Here's what's expected to be running locally vs what won't work"
- I kept thinking it was a code logic bug, then realized it was an infrastructure assumption

**2. No Visibility Into HTTP/Network Calls**

- `pg_net.http_post()` fires fire-and-forget requests I can't inspect
- Can't see logs from edge functions
- Can't easily tell: "Did the request even go out? What was the response?"
- Had to infer failure from "traits unchanged" which took extra detective work

**3. No "Health Check" Tool**

- I needed something like `docker ps` or `systemctl status` to check: "Is the LLM service running?"
- Or a simple `SELECT check_infrastructure_health()` equivalent
- Would have saved 15 minutes of hypothesis testing

### What I Wished For

1. **Environment status endpoint** - A quick query like `SELECT * FROM system.runtime_services` showing:
   - Is edge-functions available? ✅/❌
   - Is LLM service configured? ✅/❌
   - What's the config status? (URL present? Keys valid?)

2. **HTTP request logging** - At least for dev mode, log `pg_net` requests/responses to understand failures

3. **Local dev checklist** - A doc explicitly stating:
   - "These features require external infrastructure and will fail locally"
   - "Set these env vars to enable LLM"
   - "Here's how to mock the edge function for testing"

4. **Skill suggestion** - Maybe a prompt suggesting `skills_systematic_debugging` when investigating failures

### Bottom Line

**The test itself was easy.** The hard part was understanding that the test environment has **missing infrastructure dependencies** that weren't obvious from the code alone.

Better experience would be: Clear visibility into what's available vs what's stubbed/unavailable, especially for external service integrations.

---

## Agent 5: Existing Places Visible with Pending Session (player)

### 1. Initial Context - Insufficient

I was given a **test scenario but no context about the system's architecture or data model**. I didn't know:

- Whether "anonymous sessions" actually exist in this codebase (they don't - sessions get user_ids)
- What "pending review" actually means (it's a boolean flag, not a status enum value)
- Whether the game API functions I was given (`game_start`, `game_submit`) were meant for testing or if they were incomplete

I wasted significant time trying to use tools that didn't work as expected, then pivoting to the browser, then back to database queries to understand the schema.

### 2. Instructions - Unclear

The test instructions said:

- "stay anonymous" - but the system doesn't support true anonymous sessions
- "session should go to pending review" - but I had no way to trigger this state
- "verify that EXISTING places are still visible" - this was clear, but the prerequisite (creating a pending session) was impossible

**Better approach**: The instructions should have said "Try to create a pending session; if you can't, document why and test what you can."

### 3. Available Tools - Mixed

**Good**: Chrome DevTools tools worked well for UI testing once I understood the flow
**Bad**:

- `game_start`, `game_submit`, `game_state` functions failed silently or with cryptic errors
- No tool to inspect the actual game session state/schema before testing
- Had to fall back to raw SQL to understand the data model

### 4. Skills - Would Have Helped

I should have loaded `skills_systematic_debugging` earlier when I hit the first API failures. Instead, I kept trying the same broken approach.

### 5. What Would Have Made This Easier

**Before starting the test:**

1. **Schema inspection tool** - "Here's what a game session looks like, here are the valid states"
2. **Clear prerequisites** - "Anonymous sessions don't exist; here's how to test with a real user instead"
3. **API documentation** - The game functions failed without clear error messages
4. **Test data setup** - "Run this SQL to create a pending_review session, then test against it"

**During testing:**

1. **Better error messages** - "game_submit failed because X" instead of just exit code 1
2. **Fallback guidance** - "If you can't create the exact scenario, here's what to test instead"

---

## The Core Problem

I was given a **specific test scenario** (pending anonymous session) that **doesn't match the system's actual capabilities**. Rather than immediately flagging this mismatch, I spent 20+ minutes trying to make it work, then pivoting to test what I _could_ test.

**Better approach**: Load `skills_systematic_debugging` immediately, inspect the schema, and say: _"The test assumes anonymous pending sessions exist. They don't. Here's what I can test instead."_

---

## Summary: Common Themes

| Issue                    | Frequency | Suggested Fix                                     |
| ------------------------ | --------- | ------------------------------------------------- |
| Missing initial context  | 5/5       | Provide 3-4 line architecture summary before task |
| Skill discoverability    | 4/5       | Proactive skill suggestions based on task type    |
| Unclear success criteria | 4/5       | Explicit verification steps in task description   |
| No test data provided    | 3/5       | Include sample IDs or setup queries               |
| Environment visibility   | 2/5       | Health check for external dependencies            |
