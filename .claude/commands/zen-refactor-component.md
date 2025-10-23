# Refactor Component

Propose refactoring for readability, performance, or maintainability improvements.

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

**2. Delegate to Zen**

Use `mcp_zen_refactor` with Gemini:

```javascript
mcp_zen_refactor({
  step: "Analyzing component for refactoring opportunities",
  step_number: 1,
  total_steps: 2,
  next_step_required: true,
  findings: "Component has: [list complexity issues]",
  relevant_files: [
    "/Users/ciaastek/Projects/Sirocco/10x-mapmaster/src/components/..."
  ],
  refactor_type: "codesmells", // or "decompose", "modernize", "organization"
  focus_areas: ["performance", "readability"],
  model: "gemini-2.5-pro"
})
```

## Refactor Types

- **codesmells**: Detect and fix anti-patterns
- **decompose**: Split large components/functions
- **modernize**: Update to latest patterns (Composition API, etc.)
- **organization**: Improve file structure

## Output Should Include

- **Current Issues**: What's wrong
- **Proposed Changes**: How to fix
- **Impact Analysis**: What else changes
- **Testing Strategy**: How to verify

## After Refactoring

```bash
npm run type-check   # Verify types
npm run lint         # Check style
npm test:unit        # Run affected tests
```

## Example

**Before:**
```vue
<!-- Large component with mixed concerns -->
<script setup>
// 500+ lines of logic
</script>
```

**After:**
```vue
<!-- Decomposed with composables -->
<script setup>
import { useGameLogic } from '@/composables/useGameLogic'
import { useCandidates } from '@/composables/useCandidates'
// Clean, focused component
</script>
```

