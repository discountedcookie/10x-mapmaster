# Commit Message Template

Use [Conventional Commits](https://www.conventionalcommits.org/) format.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

## Types

- **feat**: New feature
- **fix**: Bug fix
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **test**: Adding or updating tests
- **docs**: Documentation changes
- **chore**: Maintenance tasks
- **perf**: Performance improvements
- **security**: Security improvements

## Examples

### Simple Feature

```
feat(game): add confidence score to result card
```

### Bug Fix with Context

```
fix(auth): prevent session timeout during active gameplay

Users were experiencing unexpected logouts during long game sessions.
This fix extends the session timeout when user interaction is detected.

Resolves #123
```

### Database Migration

```
feat(db): add game statistics table

- New game_statistics table with user aggregates
- RLS policies for user isolation
- Indexes for performance

Migration: 000004_game_statistics.sql
```

### Security Fix

```
security(rls): strengthen place insertion policy

Previous policy allowed authenticated users to insert unlimited places.
New policy adds rate limiting and validation checks.

BREAKING CHANGE: Requires new rate_limit column in places table
```

### Refactoring

```
refactor(composables): extract map logic into useMapView

Decomposed MapView component by moving map initialization and
marker management into dedicated composable for better reusability.
```

## Scope Examples

- `game`: Game logic and flow
- `auth`: Authentication and authorization
- `db`: Database schema or functions
- `ui`: UI components
- `map`: Map-related features
- `api`: External API integrations
- `tests`: Test-related changes

## Breaking Changes

If your commit introduces breaking changes, add `BREAKING CHANGE:` in the footer:

```
feat(api): change embedding endpoint response format

BREAKING CHANGE: Embedding endpoint now returns {embedding: [...]}
instead of raw array. Update all clients accordingly.
```

## Tips

- Keep the description under 50 characters
- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end of description
- Use body to explain _what_ and _why_, not _how_
