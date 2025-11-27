## 1. Rotation Logic

- [ ] 1.1 Add `shouldAutoRotate` computed based on game state (no candidates = rotate)
- [ ] 1.2 Implement bearing rotation interval (increment bearing by ~0.05 every 50ms)
- [ ] 1.3 Use `requestAnimationFrame` for smooth rotation
- [ ] 1.4 Clean up interval on component unmount

## 2. User Interaction

- [ ] 2.1 Detect user interaction (mouse/touch events on map)
- [ ] 2.2 Pause rotation on interaction
- [ ] 2.3 Resume rotation after idle timeout (e.g., 5 seconds)

## 3. Camera State

- [ ] 3.1 Set initial camera to zoomed-out globe view on home
- [ ] 3.2 Transition camera when game starts (stop rotation, zoom to region)
- [ ] 3.3 Return to rotation when game ends and user returns home

## 4. Testing

- [ ] 4.1 Visual test: globe rotates on home page
- [ ] 4.2 E2E test: rotation stops when game starts
- [ ] 4.3 E2E test: rotation pauses on user interaction
