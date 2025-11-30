## 1. Rotation Logic

- [x] 1.1 Add `shouldAutoRotate` computed based on game state (no candidates = rotate)
- [x] 1.2 Implement bearing rotation interval (increment bearing continuously)
- [x] 1.3 Use `requestAnimationFrame` for smooth rotation
- [x] 1.4 Clean up interval on component unmount

## 2. User Interaction

- [x] 2.1 Detect user interaction (mouse/touch events on map)
- [x] 2.2 Pause rotation on interaction
- [x] 2.3 Resume rotation after idle timeout (5 seconds)

## 3. Camera State

- [x] 3.1 Set initial camera to zoomed-out globe view on home (zoom: 2)
- [x] 3.2 Transition camera when game starts (stop rotation via autoRotate prop)
- [x] 3.3 Return to rotation when game ends and user returns home

## 4. Testing

- [ ] 4.1 Visual test: globe rotates on home page
- [ ] 4.2 E2E test: rotation stops when game starts
- [ ] 4.3 E2E test: rotation pauses on user interaction
