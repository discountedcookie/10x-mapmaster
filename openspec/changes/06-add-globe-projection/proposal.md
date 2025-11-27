# Change: Implement Globe Projection Map

## Why

Per `docs/architecture/ui.md`: "The map uses MapLibre's globe projection throughout - no flat map. This creates a dramatic, unique visual for a geography game." Currently, `BaseMap.vue` uses CartoDB flat 2D basemaps.

## What Changes

- **Projection**: Configure MapLibre with `projection: 'globe'`
- **Basemap**: Replace CartoDB basemaps with globe-compatible style (e.g., Mapbox Streets or custom)
- **Styling**: Add atmospheric glow effects for globe appearance
- **Performance**: Ensure smooth rendering at various zoom levels

## Impact

- Affected specs: frontend
- Affected code: `src/components/map/BaseMap.vue`
- Transforms the visual experience from flat 2D to immersive globe
