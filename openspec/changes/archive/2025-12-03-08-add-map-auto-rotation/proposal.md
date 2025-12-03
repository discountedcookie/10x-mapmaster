# Change: Implement Map Auto-Rotation on Home Page

## Why

Per `docs/architecture/ui.md`: "Home (idle) | Slow auto-rotate | Zoomed out, shows full globe". Currently the map is static on the home page, missing the dramatic globe rotation effect.

## What Changes

- **Rotation logic**: Add slow bearing rotation when no active game
- **Idle detection**: Rotate only on home page (when `candidates.length === 0`)
- **User interaction**: Pause rotation when user interacts with map
- **Resume**: Resume rotation after idle timeout

## Impact

- Affected specs: frontend
- Affected code: `src/components/map/BaseMap.vue`, `src/composables/map/`
- Creates engaging "spinning globe" effect that draws users in
