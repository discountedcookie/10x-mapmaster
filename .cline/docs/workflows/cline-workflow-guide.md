# Cline Native Workflow Guide

## Overview

This guide explains the Cline-native workflow that replaces Serena memories and other memory systems with a streamlined three-layer approach using Cline's built-in tools.

## Three-Layer Architecture

### Layer 1: Static Documentation (`.cline/docs/`)
**Purpose**: Stable, version-controlled knowledge
- Architecture decisions
- Workflows and processes
- Technical standards
- Game mechanics documentation
- Troubleshooting guides

**When to update**: Only when workflows, architecture, or decisions change
**Version control**: Tracked in git (PRs for changes)

### Layer 2: Dynamic Memory (Memory MCP)
**Purpose**: Current state, observations, and relationships
- Active work and progress
- Recent learnings and discoveries
- Entity relationships and dependencies
- Session-specific observations

**When to update**: During work sessions (every 10-15 minutes)
**Storage**: Knowledge graph with entities, relations, and observations

### Layer 3: Session Context (new_task tool)
**Purpose**: Detailed handoff between sessions
- Conversation history
- Pending tasks and next steps
- Context for continuing specific work
- Session-specific decisions

**When to use**: When switching between different types of work
**Duration**: Short-term context preservation

## Daily Workflow Pattern

### Starting a Session

1. **Read Relevant Documentation**
   ```bash
   # First-time or returning agent
   cat .cline/docs/quick-start.md
   cat .cline/docs/current-state.md
   
   # Task-specific documentation
   cat .cline/docs/workflows/safety-rules.md  # Before any work
   cat .cline/docs/technical/stack.md          # For implementation
   ```

2. **Query Memory MCP**
   ```bash
   # Search for current state and recent work
   cline "search memory for 10x-mapmaster current state and recent changes"
   ```

3. **Review Session Context** (if continuing work)
   ```bash
   # Check for existing task context
   cline "search memory for active 10x-mapmaster tasks"
   ```

### During Work

1. **Update Memory MCP Regularly**
   - Add observations as you learn/decide
   - Create relations between entities
   - Note file locations and patterns
   - Track progress and blockers

2. **Use Documentation for Reference**
   - Consult workflows for processes
   - Reference technical docs for standards
   - Check safety rules before operations

3. **Create Session Context When Needed**
   - Use `new_task` when switching focus
   - Include full context for handoffs
   - Preserve conversation history

### Ending a Session

1. **Update Memory MCP**
   - Summarize work completed
   - Note current state and progress
   - Add observations for next session
   - Create relations for dependencies

2. **Create Session Context** (if work incomplete)
   ```bash
   cline "create new task with current 10x-mapmaster work context"
   ```

3. **Update Documentation** (only if needed)
   - Architecture changes
   - Workflow improvements
   - New safety rules
   - Major decisions

## Memory MCP Usage Patterns

### Entity Creation
```bash
# Create project entity
cline "create memory entity for 10x-mapmaster project with observations about current state"

# Create feature entities
cline "create memory entity for algorithmic filtering system with technical details"

# Create technology entities
cline "create memory entity for Vue 3 frontend with stack details"
```

### Observation Updates
```bash
# Add progress observations
cline "add observation to 10x-mapmaster entity: completed vector system optimization"

# Add technical discoveries
cline "add observation to algorithmic filtering entity: fixed pgvector performance issue"

# Add file locations
cline "add observation: vector optimization in src/lib/vector-optimizer.ts:45-67"
```

### Relation Management
```bash
# Create dependencies
cline "create relation: algorithmic filtering depends_on pgvector extension"

# Track implementations
cline "create relation: Vue 3 frontend implements game mechanics"

# Note fixes
cline "create relation: bug fix resolves vector similarity calculation issue"
```

## Documentation vs Memory Decision Tree

### Use Documentation When:
- ✅ Architecture decisions and rationale
- ✅ Workflow processes and standards
- ✅ Technical specifications
- ✅ Safety rules and guidelines
- ✅ Game mechanics documentation
- ✅ Troubleshooting procedures

### Use Memory MCP When:
- ✅ Current work progress and status
- ✅ Recent learnings and discoveries
- ✅ File locations and line numbers
- ✅ Session-specific observations
- ✅ Entity relationships
- ✅ Temporary decisions and experiments

### Use new_task When:
- ✅ Switching between different work types
- ✅ Preserving conversation context
- ✅ Handing off incomplete work
- ✅ Continuing complex multi-session tasks

## Advantages Over Previous Systems

### Compared to Serena Memories
- **Simpler**: Two clear systems instead of file-based memories
- **Searchable**: Knowledge graph with semantic search
- **Relational**: Entity relationships and dependencies
- **Dynamic**: Real-time updates during work
- **Focused**: Clear separation of concerns

### Compared to Multiple Memory Systems
- **Native**: Uses Cline's built-in tools
- **Integrated**: Seamless workflow with existing tools
- **Consistent**: Single interface for all memory operations
- **Reliable**: No external dependencies or configuration
- **Scalable**: Grows with project complexity

## Migration Status

### Completed ✅
- Created `.cline/docs/` structure
- Migrated critical documentation
- Established workflow patterns
- Created safety rules and technical docs

### In Progress 🔄
- Memory MCP entity initialization
- Entity relationship creation
- Observation pattern establishment

### Pending ⏳
- Full memory graph population
- Session context examples
- Workflow optimization based on usage

## Best Practices

### Memory Management
1. **Update frequently**: Every 10-15 minutes during active work
2. **Be specific**: Include file names, line numbers, technical details
3. **Create relations**: Connect entities to show dependencies
4. **Use observations**: Track decisions, discoveries, and changes

### Documentation Management
1. **Version control**: All docs in git with PR reviews
2. **Update rarely**: Only for significant changes
3. **Be comprehensive**: Include full context and examples
4. **Maintain structure**: Follow established organization

### Session Management
1. **Start with context**: Read docs + query memory
2. **Update during work**: Regular memory updates
3. **End with summary**: Memory updates + task creation
4. **Handoff cleanly**: Use new_task for context preservation

## Troubleshooting

### Memory MCP Issues
- **Entity not found**: Create entity with basic observations
- **Missing relations**: Create relations between existing entities
- **Search results poor**: Add more specific observations
- **Performance slow**: Trim old observations, focus on current work

### Documentation Issues
- **Out of date**: Update with current information
- **Missing context**: Add examples and use cases
- **Hard to find**: Update README with clear navigation
- **Inconsistent**: Standardize format and structure

### Workflow Issues
- **Context loss**: Use new_task for session handoffs
- **Memory gaps**: Update memory more frequently
- **Documentation drift**: Regular reviews and updates
- **Tool confusion**: Refer to this guide for patterns

## Getting Help

1. **Read this guide**: Complete workflow reference
2. **Check documentation**: `.cline/docs/` for detailed information
3. **Query memory**: Search for current state and observations
4. **Ask user**: For production operations and major decisions
5. **Create task**: Use new_task for complex multi-session work

This workflow provides a clean, efficient system for managing project knowledge and context using Cline's native capabilities.
