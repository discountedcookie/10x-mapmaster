# Original Prompt (Extracted from Conversation)

We have a geographic guessing game project (10x-mapmaster) with comprehensive architecture documentation in `docs/architecture/`. The implementation was done by AI agents who marked everything as complete, but they actually skimmed the code, saw some working stuff, and marked tasks done without proper implementation. The quality is far from the docs - most notably, LLM isn't being used anywhere on the backend, questions aren't in natural language, the map isn't a globe, and markers aren't 3D.

The app is partially working - you can play a successful game via SQL functions and browser - but the algorithm doesn't work like designed in docs. The current implementation wrongly uses `get_llm_question` to generate questions via LLM, but the docs say we should pick geographic_region/trait ourselves (game algorithms) and use LLM only to translate to natural language instead of templating. There are string templates like "Does it have" that should be eliminated.

We want to fix this by running a systematic audit using 3 parallel code-reviewer subagents: one for database functions, one for edge functions, and one for frontend UI (skipping game store internals, focusing on how store methods are used). Each produces a gap list per doc section with 1-2 sentence explanations and fix suggestions. Then we create OpenSpec change proposals named `01-fix-...`, `02-fix-...` etc., following the very granular, verb-led naming in AGENTS.md.

Backend must be fixed first before touching frontend - no doubling work on a broken foundation. All docs have equal priority for this full project audit.

---

_Extracted by Clavix on Thu Nov 27 2025. See optimized-prompt.md for enhanced version._
