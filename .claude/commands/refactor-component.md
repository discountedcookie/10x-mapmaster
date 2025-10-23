# Refactor Component (Serena)

Propose refactoring for readability, performance, or maintainability improvements using local Serena tools.

## When to Use

- Component identified as overly complex
- Performance optimization needed
- Code smells detected
- Modernization required

## Workflow

**1. Analyze with Serena**

```javascript
// Get component overview
mcp_serena_get_symbols_overview("src/components/...")

// Find specific symbols
mcp_serena_find_symbol({
  name_path: "ComponentName/methodName",
  relative_path: "src/components/...",
  include_body: true
})

// Check references
mcp_serena_find_referencing_symbols({
  name_path: "methodName",
  relative_path: "src/components/..."
})
```

**2. After Refactoring**

```bash
npm run type-check   # Verify types
npm run lint         # Check style
npm test:unit        # Run affected tests
```
