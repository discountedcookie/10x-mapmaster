## 1. Dependencies

- [ ] 1.1 Add `@deck.gl/core`, `@deck.gl/layers`, `@deck.gl/mapbox` to package.json
- [ ] 1.2 Add TypeScript types for deck.gl
- [ ] 1.3 Configure Vite to bundle deck.gl correctly

## 2. 3D Layer Component

- [ ] 2.1 Create `src/components/map/Deck3DLayer.vue` component
- [ ] 2.2 Initialize deck.gl MapboxOverlay for MapLibre integration
- [ ] 2.3 Implement PolygonLayer with extrusion based on confidence
- [ ] 2.4 Add confidence-to-height mapping function

## 3. Geometry Handling

- [ ] 3.1 Fetch polygon geometry from candidates (if available)
- [ ] 3.2 Generate circle polygons for places without geometry
- [ ] 3.3 Handle coordinate transformations for globe projection

## 4. Visual States

- [ ] 4.1 Implement top candidate highlight (tallest + glow)
- [ ] 4.2 Implement eliminated state (shrinks into surface)
- [ ] 4.3 Add smooth height transitions on confidence changes

## 5. Integration

- [ ] 5.1 Replace MapMarker usage with Deck3DLayer in MapLayout
- [ ] 5.2 Connect to map state composable for candidate data
- [ ] 5.3 Handle click events on 3D polygons

## 6. Testing

- [ ] 6.1 Visual test: 3D markers render with correct heights
- [ ] 6.2 Performance test: 100+ candidates render smoothly
- [ ] 6.3 E2E test: clicking 3D marker selects candidate
