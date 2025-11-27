# Change: Implement 3D Extruded Polygon Markers

## Why

Per `docs/architecture/ui.md`: "Candidate places are visualized as 3D extruded polygons using deck.gl's `PolygonLayer`. The place's actual polygon shape extrudes upward from the globe, with height representing confidence." Currently using simple 2D circular markers.

## What Changes

- **Dependencies**: Add deck.gl packages (`@deck.gl/core`, `@deck.gl/layers`, `@deck.gl/mapbox`)
- **3D Layer**: Create `Deck3DLayer.vue` component using PolygonLayer
- **Height mapping**: Map candidate confidence to extrusion height
- **Geometry**: Fetch polygon geometry from places table, generate circles for places without geometry
- **Integration**: Replace MapMarker with Deck3DLayer

## Impact

- Affected specs: frontend
- Affected code: `src/components/map/`, `package.json`
- Confidence becomes visually dramatic as 3D height rather than color/size
