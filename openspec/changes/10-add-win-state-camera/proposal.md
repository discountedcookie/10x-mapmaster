# Change: Implement Win State Camera Orbit

## Why

Per `docs/architecture/ui.md`: "Win/End State: Camera orbits gently around winning place. Zoom to show place polygon (if available). Success glow/highlight on winning pin." Currently the camera just frames the winning place without orbital animation or glow.

## What Changes

- **Orbital animation**: Implement gentle camera orbit around winning place
- **Zoom behavior**: Zoom to show place polygon at appropriate level
- **Success highlight**: Add glow/pulse effect on winning marker
- **End state**: Different treatment for give-up vs win scenarios

## Impact

- Affected specs: frontend
- Affected code: `src/views/GameView.vue`, `src/components/map/`
- Creates celebratory visual feedback when player wins
