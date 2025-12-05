---
agent: build
description: Run gameplay tests via SQL and browser with subagents
subtask: false
---

# Gameplay Testing Command

Run comprehensive gameplay tests using 3 parallel subagents to verify game mechanics.

## Test Configuration

$ARGUMENTS

If no arguments provided, run all 3 tests:
- SQL with world places (geographic questions)
- SQL with Poland places (semantic questions)  
- Browser UI testing

## Instructions

Load the `subagent-workflow` skill first, then dispatch these agents **in parallel**:

### 1. SQL World Places (@supabase-expert)

```
TASK: Test game mechanics via SQL using places from around the world (for geographic question testing).

INSTRUCTIONS:
1. Load the `skills_gameplay_sql` tool - it contains the complete workflow
2. Play 2-3 complete game sessions with DIFFERENT random places from around the world
3. For each session, play through ALL turns until the game ends

REPORT BACK WITH:
1. **Does the game work?** - Did start_game(), play_turn() execute without errors?
2. **Question Quality** - List questions each turn. Do they sound natural?
3. **Candidate Observation** - After EACH turn, report top 3 candidates and confidence scores
4. **Probability Changes** - Are confidence/probability scores changing between turns?
5. **Any Bugs or Issues** - Anything unexpected
```

### 2. SQL Poland Places (@supabase-expert)

```
TASK: Test game mechanics via SQL using places from POLAND (for semantic/trait question testing).

INSTRUCTIONS:
1. Load the `skills_gameplay_sql` tool - it contains the complete workflow
2. Play 2-3 complete game sessions with DIFFERENT places from Poland
3. For each session, play through ALL turns until the game ends

REPORT BACK WITH:
1. **Does the game work?** - Did start_game(), play_turn() execute without errors?
2. **Question Quality** - Are semantic/trait questions being asked?
3. **Candidate Observation** - After EACH turn, report top 3 candidates and confidence scores
4. **Probability Changes** - Are confidence/probability scores changing between turns?
5. **Poland-Specific** - Are semantic questions prioritized over geographic ones?
6. **Any Bugs or Issues** - Anything unexpected
```

### 3. Browser Testing (@player)

```
TASK: Test the game through the browser UI.

INSTRUCTIONS:
1. Load the `skills_gameplay_browser` tool - it contains the workflow
2. Navigate to the game (localhost:5173 or dev server)
3. Play through 2-3 complete game sessions

REPORT BACK WITH:
1. **Does the game work in browser?** - Can you start, play, and complete games?
2. **UI Observations** - Questions display, Yes/No buttons, map, feedback
3. **Question Quality** - Do questions sound natural?
4. **Game Flow** - Smooth or jarring?
5. **End State** - Is the result shown clearly?
6. **Any Bugs or UI Issues** - Console errors, visual glitches
```

## After All Agents Complete

Compile a summary report with:

| Agent | Test Type | Games | Success Rate | Verdict |
|-------|-----------|-------|--------------|---------|
| SQL World | Geographic | X/Y | Z% | PASS/FAIL |
| SQL Poland | Semantic | X/Y | Z% | PASS/FAIL |
| Browser | UI | X/Y | Z% | PASS/FAIL |

### Key Findings

1. **Game Mechanics**: Working / Not Working
2. **Question Quality**: Natural / Issues Found
3. **Candidate Behavior**: Correct / Issues Found
4. **Probability Updates**: Working / Not Working
5. **Browser vs SQL Consistency**: Matching / DISCREPANCY (critical bug!)

### Issues Found

List all issues by severity:
- Critical (game-breaking)
- Moderate (affects gameplay)  
- Minor (cosmetic/informational)

## Note Session IDs

Always record session IDs for follow-up:
- SQL World: `ses_XXX`
- SQL Poland: `ses_YYY`
- Browser: `ses_ZZZ`
