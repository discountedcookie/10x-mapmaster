## 1. Orbital Animation

- [x] 1.1 Create `usePlacePresentation` composable for camera orbit logic
- [x] 1.2 Implement gentle circular orbit around place coordinates
- [x] 1.3 Use `requestAnimationFrame` for smooth animation
- [x] 1.4 Set appropriate orbit radius and speed (30s full rotation)

## 2. Zoom and Framing

- [x] 2.1 Implement zoom-pitch correlation (zoom 2-12 → pitch 0-55°)
- [x] 2.2 Transition camera smoothly with flyTo/easeTo
- [x] 2.3 Handle offset for UI panels

## 3. Visual Effects

- [ ] 3.1 Add glow effect to winning marker - DEFERRED
- [ ] 3.2 Implement pulse animation on win - DEFERRED
- [ ] 3.3 Different styling for give-up state (muted vs celebratory) - DEFERRED

## 4. Integration

- [x] 4.1 Trigger animation in GameWon.vue and GameSubmissionPending.vue
- [x] 4.2 Stop animation on user interaction (mousedown/touchstart)
- [x] 4.3 Cleanup on unmount via onUnmounted hook

## 5. Testing

- [ ] 5.1 Visual test: camera orbits correctly on win - DEFERRED
- [ ] 5.2 E2E test: win state triggers animation - DEFERRED
- [ ] 5.3 Test animation cleanup on navigation - DEFERRED
