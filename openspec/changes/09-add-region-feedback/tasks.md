## 1. Region Layer

- [ ] 1.1 Create `GeographicRegionLayer.vue` component
- [ ] 1.2 Fetch region geometries from database via composable
- [ ] 1.3 Add MapLibre fill layer for regions with opacity control

## 2. State Management

- [ ] 2.1 Add `activeRegions` and `eliminatedRegions` to map state
- [ ] 2.2 Update region state when geographic answers are given
- [ ] 2.3 Expose region state from game store

## 3. Animations

- [ ] 3.1 Implement fade-out animation for eliminated regions (opacity 1 -> 0.3 -> 0)
- [ ] 3.2 Implement highlight animation for confirmed regions
- [ ] 3.3 Use CSS transitions or MapLibre paint property animations

## 4. Integration

- [ ] 4.1 Connect to game store for answer events
- [ ] 4.2 Update region visibility when candidates change
- [ ] 4.3 Clear all regions when game ends

## 5. Testing

- [ ] 5.1 Visual test: regions fade correctly on YES/NO answers
- [ ] 5.2 E2E test: geographic question answer updates region display
- [ ] 5.3 Performance test: multiple regions render smoothly
