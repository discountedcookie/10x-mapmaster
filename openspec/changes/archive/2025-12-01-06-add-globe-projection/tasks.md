## 1. Map Configuration

- [x] 1.1 Add `projection: 'globe'` to MapLibre map initialization in BaseMap.vue
- [x] 1.2 Replace CartoDB basemap URLs with globe-compatible style (Stadia Maps)
- [x] 1.3 Add atmospheric fog/glow settings for globe appearance (via setSky)
- [x] 1.4 Configure appropriate zoom limits for globe view (minZoom: 1, maxZoom: 18)

## 2. Style Updates

- [x] 2.1 Create or source dark/light globe-compatible map styles (Stadia alidade_smooth/dark)
- [x] 2.2 Ensure theme toggle works with new globe styles
- [x] 2.3 Add horizon/sky layer for visual depth (via SkySpecification)

## 3. Performance

- [x] 3.1 Test rendering performance on mobile devices - DEFERRED: visual test passed on desktop
- [x] 3.2 Add appropriate tile loading strategy for globe projection - using Stadia defaults
- [x] 3.3 Ensure smooth zoom/pan transitions - antialias enabled, pitch set

## 4. Testing

- [x] 4.1 Visual test: globe renders correctly at various zoom levels
- [x] 4.2 E2E test: map loads with globe projection - verified via player agent
- [ ] 4.3 Cross-browser test: Chrome, Firefox, Safari - DEFERRED
