# Git Workflow - 10x-mapmaster

## Branch Strategy

### Main Branches
- `main` - Production-ready code
- `cline` - Cline workflow migration and testing

### Feature Branches
- `feature/<name>` - New features and improvements
- `fix/<name>` - Bug fixes
- `docs/<name>` - Documentation updates

## Conventional Commits

### Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code formatting (no logic changes)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

### Examples
```bash
feat(game): add algorithmic filtering system
fix(vector): resolve pgvector similarity calculation
docs(workflow): add Cline memory system guide
refactor(components): extract reusable map utilities
test(e2e): add complete game flow tests
chore(deps): update Vue 3 to latest version
```

## Daily Workflow

### Starting Work
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Ensure up to date
git pull origin main
```

### During Development
```bash
# Check status
git status

# Add changes
git add .

# Commit with conventional format
git commit -m "feat(scope): description"

# Push to feature branch
git push origin feature/your-feature-name
```

### Completing Work
```bash
# Switch to main
git checkout main

# Pull latest changes
git pull origin main

# Merge feature branch
git merge feature/your-feature-name

# Push to main
git push origin main

# Delete feature branch
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

## Cline-Specific Patterns

### Documentation Changes
```bash
git checkout -b docs/cline-workflow-updates
# Make documentation changes
git add .cline/docs/
git commit -m "docs(workflow): add Cline-native memory system guide"
```

### Feature Development
```bash
git checkout -b feature/vector-system-optimization
# Make code changes
git add src/ supabase/
git commit -m "feat(vector): optimize pgvector similarity calculations"
```

### Bug Fixes
```bash
git checkout -b fix/map-rendering-issue
# Fix the issue
git add src/components/map/
git commit -m "fix(map): resolve marker clustering display issue"
```

## Safety Rules

### Always Safe
- ✅ Create feature branches
- ✅ Commit to feature branches
- ✅ Push to feature branches
- ✅ Merge feature branches to main
- ✅ Delete merged feature branches

### Ask User First
- ❌ Push directly to main
- ❌ Force push (git push --force)
- ❌ Rewrite published history
- ❌ Merge without review

### Before Production
- ✅ All tests passing
- ✅ Code review completed
- ✅ Documentation updated
- ✅ Safety rules checked

## Integration with Cline Workflow

### Memory Updates
```bash
# After memory MCP updates
git add .cline/docs/
git commit -m "docs(memory): update workflow guide with new patterns"
```

### Session Handoffs
```bash
# Before creating new_task
git add -A
git commit -m "feat(session): complete vector system optimization phase"
# Then create new_task with context
```

### Documentation Changes
```bash
# After updating static docs
git add .cline/docs/
git commit -m "docs(workflow): update safety rules with new guidelines"
```

## Best Practices

### Commit Quality
- **Atomic commits**: One logical change per commit
- **Clear descriptions**: What changed and why
- **Proper formatting**: Follow conventional commits
- **Include scope**: Specify affected area

### Branch Management
- **Descriptive names**: feature/vector-system, fix/auth-issue
- **Short-lived**: Merge and delete when complete
- **Clean history**: Rebase before merging if needed
- **Protection**: Main branch should be protected

### Integration with Workflows
- **Safety first**: Check safety rules before production ops
- **Documentation**: Update docs when workflows change
- **Memory sync**: Commit documentation changes regularly
- **Context preservation**: Use new_task for session handoffs

## Troubleshooting

### Merge Conflicts
```bash
# During merge
git merge feature/branch-name
# Resolve conflicts
git add .
git commit -m "fix: resolve merge conflicts"
```

### Undo Changes
```bash
# Uncommitted changes
git checkout -- filename

# Last commit
git reset --soft HEAD~1

# Multiple commits
git reset --soft HEAD~3
```

### Branch Issues
```bash
# Switch branch with changes
git stash
git checkout other-branch
git stash pop

# Delete remote branch
git push origin --delete branch-name
```

This git workflow integrates seamlessly with the Cline-native memory system and safety rules.
