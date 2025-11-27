# Change: Implement Geographic Region Feedback

## Why

Per `docs/architecture/ui.md`: "When a geographic question is answered: YES - Region remains, areas outside fade out. NO - Region fades out (semi-transparent -> hidden)". Currently there is no geographic region visualization or fade logic.

## What Changes

- **Region layer**: Add MapLibre layer for geographic regions from database
- **Fade animations**: Implement fade-in/fade-out based on answers
- **State management**: Track active/eliminated regions in map state
- **Visual feedback**: Use semi-transparency and opacity transitions

## Impact

- Affected specs: frontend
- Affected code: `src/components/map/`, `src/composables/map/`
- Helps players visually understand narrowing search space
