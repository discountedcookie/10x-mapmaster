# Serena Workflow Patterns

## Code Analysis Workflow

1. **Start with Overview**
   ```bash
   # Get file structure overview
   mcp_serena_get_symbols_overview
   
   # Find specific symbols
   mcp_serena_find_symbol
   ```

2. **Targeted Reading**
   ```bash
   # Read specific symbol with body
   mcp_serena_find_symbol --include_body=true
   
   # Find references
   mcp_serena_find_referencing_symbols
   ```

3. **Intelligent Editing**
   ```bash
   # Replace symbol body
   mcp_serena_replace_symbol_body
   
   # Insert after/before symbols
   mcp_serena_insert_after_symbol
   mcp_serena_insert_before_symbol
   ```

## Memory Management

- **Write memories** for important project information
- **Read memories** when starting new tasks
- **Update memories** as project evolves
- **Delete memories** when no longer relevant

## Best Practices

1. **Always use symbolic tools first** - avoid reading entire files
2. **Use overview tools** to understand structure
3. **Read only what you need** - be token efficient
4. **Use memory system** to maintain context
5. **Think before editing** - use `think_about_task_adherence`
6. **Summarize changes** after completion

## Common Patterns

### Adding New Features
1. Read relevant memories
2. Analyze existing code structure
3. Plan implementation
4. Implement with symbolic tools
5. Test with Playwright
6. Update memories

### Debugging
1. Use search patterns to find issues
2. Analyze with Serena tools
3. Test with browser automation
4. Fix with targeted edits
5. Document solution in memory
