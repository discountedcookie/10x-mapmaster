## 1. Dependencies

- [x] 1.1 Add `@deck.gl/core`, `@deck.gl/layers`, `@deck.gl/mapbox` to package.json
- [x] 1.2 Add TypeScript types for deck.gl (built-in types)
- [x] 1.3 Configure Vite to bundle deck.gl correctly (uses default config)

## 2. 3D Layer Component

- [x] 2.1 Create `src/components/map/Deck3DLayer.vue` component
- [x] 2.2 Initialize deck.gl MapboxOverlay for MapLibre integration
- [x] 2.3 Implement PolygonLayer with extrusion based on confidence
- [x] 2.4 Add confidence-to-height mapping function

## 3. Geometry Handling

- [x] 3.1 Fetch polygon geometry from candidates (if available) - generates circles
- [x] 3.2 Generate circle polygons for places without geometry
- [x] 3.3 Handle coordinate transformations for globe projection

## 4. Visual States

- [x] 4.1 Implement top candidate highlight (tallest + different color)
- [x] 4.2 Implement eliminated state (shorter polygons)
- [ ] 4.3 Add smooth height transitions on confidence changes - DEFERRED: needs animation layer

## 5. Integration

- [x] 5.1 Replace MapMarker usage with Deck3DLayer in MapLayout (for game candidates)
- [x] 5.2 Connect to map state composable for candidate data
- [ ] 5.3 Handle click events on 3D polygons - DEFERRED: needs picking setup

## 6. Testing

- [ ] 6.1 Visual test: 3D markers render with correct heights
- [ ] 6.2 Performance test: 100+ candidates render smoothly
- [ ] 6.3 E2E test: clicking 3D marker selects candidate
