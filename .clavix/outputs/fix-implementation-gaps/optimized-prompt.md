# Optimized Prompt (Clavix Enhanced)

## Phase 1: Parallel Codebase Audit

Execute 3 code-reviewer subagents simultaneously to audit implementation against `docs/architecture/`:

| Agent | Scope                 | Docs                                             | Focus                                                |
| ----- | --------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| 1     | `supabase/db/`        | `algorithm.md`, `architecture.md`, `gameplay.md` | Database functions, game logic, scoring              |
| 2     | `supabase/functions/` | `algorithm.md`, `operations.md`                  | Edge functions, LLM integration                      |
| 3     | `src/` (UI only)      | `ui.md`, `gameplay.md`                           | Components, map, markers (skip game store internals) |

**Output per agent:** Gap list organized by doc section:

```
### [doc-name.md] Section: [Section Name]
- **Gap:** [1-2 sentence description]
- **Location:** [file:line]
- **Fix:** [Suggested approach]
```

## Phase 2: OpenSpec Change Creation

For each gap identified, create granular OpenSpec changes:

- **Naming:** `01-fix-[specific-issue]`, `02-fix-[specific-issue]`, etc.
- **Convention:** Verb-led, kebab-case per `openspec/AGENTS.md`
- **Structure:** `proposal.md` + `tasks.md` + spec deltas in `specs/[capability]/`
- **Validation:** Run `openspec validate [change] --strict` before finalizing

## Known Critical Gaps (Pre-Identified)

1. **LLM Question Translation:** `call-llm` edge function exists but unused
   - Wrong: `get_llm_question` generates questions via LLM
   - Correct: Algorithm selects `geographic_region/trait` → `call-llm` translates to natural language
   - Remove string templates ("Does it have" patterns)

2. **Map Display:** Currently flat map, should be globe
3. **Markers:** Currently 2D, should be 3D

## Execution Constraints

- **Sequence:** ALL backend changes implemented before ANY frontend work
- **Scope:** Full audit - all 5 architecture docs weighted equally
- **Granularity:** One OpenSpec change per logical fix (not batched)

## Success Criteria

- [ ] 5 architecture docs audited (algorithm, architecture, gameplay, operations, ui)
- [ ] Gap list produced for each doc section
- [ ] OpenSpec change created per gap with `--strict` validation passing
- [ ] Backend: LLM translates questions (no templates)
- [ ] Backend: Algorithm matches `algorithm.md` design
- [ ] Frontend: Globe map with 3D markers

---

## Clavix Intelligence Improvements Applied

1. **[STRUCTURED]** - Reorganized into clear Phase 1 (Audit) and Phase 2 (Fix) with table format for agent assignment
2. **[CLARIFIED]** - Made audit output format explicit with template showing expected gap documentation
3. **[ACTIONABILITY]** - Converted known issues into numbered "Critical Gaps" checklist for immediate reference
4. **[COMPLETENESS]** - Added explicit success criteria as checkboxes for verification
5. **[EFFICIENCY]** - Condensed 4 paragraphs into structured sections with clear headers and constraints

---

_Optimized by Clavix on Thu Nov 27 2025. This version is ready for implementation._
