## 1. Region Layer

- [x] 1.1 Create `GeographicRegionLayer.vue` component
- [ ] 1.2 Fetch region geometries from database via composable - DEFERRED: needs RPC endpoint
- [x] 1.3 Add MapLibre fill layer for regions with opacity control

## 2. State Management

- [x] 2.1 Add `activeRegions` and `eliminatedRegions` support to component
- [ ] 2.2 Update region state when geographic answers are given - DEFERRED: needs game state integration
- [ ] 2.3 Expose region state from game store - DEFERRED: needs backend support

## 3. Animations

- [x] 3.1 Implement fade-out animation for eliminated regions (via opacity paint property)
- [x] 3.2 Implement highlight animation for confirmed regions (green color)
- [x] 3.3 Use MapLibre paint property for state-based styling

## 4. Integration

- [ ] 4.1 Connect to game store for answer events - DEFERRED: needs game state changes
- [x] 4.2 Update region visibility when regions prop changes
- [x] 4.3 Clear all regions when component unmounts

## 5. Testing

- [ ] 5.1 Visual test: regions fade correctly on YES/NO answers
- [ ] 5.2 E2E test: geographic question answer updates region display
- [ ] 5.3 Performance test: multiple regions render smoothly
