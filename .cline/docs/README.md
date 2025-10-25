# 10x-mapmaster Documentation - Cline Native Workflow

## 🎯 Quick Start

**TL;DR**: Intelligent geography guessing game using **Vue 3 + TypeScript + Supabase + pgvector + MapLibre**. Players describe places, system uses vector embeddings + yes/no questions to identify them. Pure algorithmic filtering (pgvector + PostGIS), no hardcoded logic.

## 📁 Documentation Structure

### 🚀 Getting Started
- `quick-start.md` - TL;DR, START HERE checklist, daily commands
- `current-state.md` - Latest milestone, active work, recent changes

### 🔧 Workflows
- `workflows/database.md` - Migration patterns, seed workflow, Supabase MCP patterns
- `workflows/safety-rules.md` - Critical safety rules, production safeguards
- `workflows/testing.md` - Test stack, commands, RLS testing
- `workflows/git.md` - Feature branch workflow, commit standards

### 🏗️ Technical Reference
- `technical/stack.md` - Tech stack, patterns, file structure
- `technical/code-standards.md` - Non-negotiables, conventions, patterns
- `technical/external-apis.md` - Nominatim rate limits, MapLibre lazy loading

### 🎮 Game Mechanics
- `game-mechanics/complete-flow.md` - End-to-end game flow
- `game-mechanics/vector-system.md` - Embeddings, learning, place enrichment
- `game-mechanics/question-system.md` - Question selection algorithm, effectiveness tracking

### 🎨 Design & Architecture
- `design/architecture.md` - Major decisions, rationale, UI patterns, auth flow

### 🔍 Troubleshooting
- `troubleshooting/known-issues.md` - Known bugs, workarounds, common gotchas
- `troubleshooting/solutions.md` - Debugging patterns, solutions to common problems

## 🔄 Cline Memory System

This documentation works with Cline's native memory tools:

### Three-Layer Architecture
1. **Static Documentation** (this folder) - Stable, version-controlled knowledge
2. **Dynamic Memory** (Memory MCP) - Current state, observations, relations
3. **Session Context** (new_task tool) - Detailed handoff between sessions

### Usage Pattern
1. **Start Session**: Read relevant docs + query memory MCP
2. **During Work**: Update memory MCP with observations
3. **End Session**: Update memory MCP + create new_task if switching focus
4. **Architecture Changes**: Update docs only when workflows/decisions change

## 🎯 Core Principle

**Session-First Architecture**: Database is source of truth. Game session created immediately, all state derived from relations. Pure algorithmic filtering - no hardcoded business logic.

## 📊 Current Status

**Latest Milestone**: ✅ ALGORITHMIC FILTERING COMPLETE (October 23, 2025)
- Removed 40+ lines of hardcoded CASE WHEN statements
- Implemented pure pgvector + PostGIS filtering
- Geographic questions now visible (0.6 baseline score)
- Test results: 2 questions to solve Machu Picchu (15→2 candidates)

## 🚨 Production Safety

**NEVER on production:**
- ❌ `supabase db reset --remote`
- ❌ `npm run seed:places` / `npm run seed:questions`
- ❌ Destructive operations (DROP, TRUNCATE, DELETE without WHERE)

**ALWAYS:**
- ✅ Feature branches for all work
- ✅ Local DB reset: `npx supabase db reset` (SAFE)
- ✅ Non-destructive migrations only
- ✅ RLS enabled on all tables
- ✅ Security review for schema/auth changes
