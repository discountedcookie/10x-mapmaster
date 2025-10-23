# Generate Feature Plan

Break down complex feature requests into step-by-step implementation plans using Zen MCP.

## When to Use

- New feature involves multiple files or complex logic
- Architectural decisions needed
- Database schema changes required
- Need to validate approach before implementation

## Workflow

```
1. Analyze requirements from user request
2. Check product vision (AGENTS.md)
3. Review current architecture (project-setup-and-current-state memory)
4. Delegate to Zen for comprehensive planning
```

## Zen Delegation

Use `mcp_zen_planner` with Gemini (1M token context):

```javascript
mcp_zen_planner({
  step: "Step 1: Analyze feature requirements and architectural fit",
  step_number: 1,
  total_steps: 5,
  next_step_required: true,
  findings: "Feature requires: [components, DB changes, UI updates]",
  model: "gemini-2.5-pro"
})
```

## Output Should Include

- Feature overview (what & why)
- Technical approach (architecture, patterns)
- Implementation steps with file paths
- Testing strategy (unit, DB, E2E)
- Security review if needed
- Rollout strategy

## After Planning

- Share plan with user for approval
- Create TODO items if approved
- Start implementation on feature branch: `git checkout -b feature/<name>`
