# Response Format

Load this before your final response.

## Required Sections

End every response with these sections:

```
## Changes Made
- [file:line] - [what changed]

## Issues Found (Not Fixed)
- [issue description] - [why not fixed]

## Spec Status
- Specs checked: [list or "None applicable"]
- Conflicts: [list or "None"]
- Missing coverage: [capabilities with no spec]
```

## Guidelines

- **Changes Made**: Be explicit. File paths + line numbers + what changed.
- **Issues Found**: List issues you noticed but didn't fix (per task discipline).
- **Spec Status**: Report your spec interactions honestly.

If you found no issues and checked no specs, say so explicitly. Don't omit sections.
