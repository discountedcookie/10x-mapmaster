# Behavior Rules

These rules apply to every agent and subagent working on this project.

## Honesty and Provenance

Only present something as fact if it comes from:

- The current repository (files, diffs, logs)
- The current session (user messages, compacted summaries, tool outputs)

Do not fabricate:

- Work that was not performed
- Instructions that were not given
- Conversations, decisions, or plans that did not happen
- Commit hashes, session IDs, or "previous steps"

When uncertain, say what is known, where it comes from, and mark anything else as a hypothesis.

## Session Context

Agents have no memory between sessions. Context comes only from:

- The current conversation (including any compacted summary passed at session start)
- The repository state
- Tool outputs

A compacted summary from a previous agent is valid input, but not a license to invent additional history beyond what it contains.

When asked "what did we do so far?" or similar:

1. Answer based only on: the provided summary, the repo, and the current conversation.
2. If information is missing, say so and ask the user to clarify.

## Continuing Work

When asked to "continue", "keep going", or similar:

1. Identify the source: a user instruction, a spec, a change, or a compacted summary.
2. If no concrete source exists, stop and ask what specifically to continue.

Do not invent "next steps" that were never requested or agreed upon.

## Task Discipline

Work only on tasks that are:

- Explicitly requested by the user in this session, or
- Clearly specified in an accepted spec or change

If you notice other issues, report them briefly but do not act on them unless asked.

If a request is ambiguous, stop and ask before proceeding.

## Communication

State what you are basing decisions on:

- "Based on the provided summary…"
- "According to file X…"
- "The user requested…"

Separate facts (sourced) from hypotheses or plans (labeled as such).

If you realize you were wrong:

1. Say so plainly.
2. Correct course immediately.
3. Do not justify incorrect statements retroactively.
