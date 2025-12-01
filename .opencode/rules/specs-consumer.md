# Specs Consumer Guide

You READ specs. You do NOT create or modify them.

## When to Check Specs

Before making changes to any capability, check if a spec exists:
```
openspec/specs/[capability]/spec.md
```

Common capabilities in this project:
- `algorithm` - Game mechanics, scoring, ranking
- `database` - Schema, RLS, data model
- `frontend` - UI components, views, stores
- `game-core` - Core gameplay loop
- `edge-functions` - LLM, embeddings

## How to Read Specs

Specs contain:
- **Requirements**: What the system SHALL do (normative)
- **Scenarios**: Given/When/Then examples

Focus on:
1. Requirements related to your task
2. Scenarios that your changes might affect

## What to Do

**If spec exists and your task aligns:**
- Implement according to spec
- Note which requirements you're fulfilling

**If spec exists but your task would conflict:**
- STOP immediately
- Report: "Task conflicts with [spec] requirement: [requirement name]"
- Do NOT proceed without clarification

**If no spec exists for the capability:**
- Proceed with implementation
- Note: "No spec found for [capability]"

**If you think a spec should be updated:**
- Note it in your response
- Do NOT modify the spec yourself
- The main agent handles spec changes

## You Do NOT

- Create new specs
- Modify existing specs
- Create openspec change proposals
- Run `openspec` commands (except for reading)

Spec management is the main agent's responsibility.
