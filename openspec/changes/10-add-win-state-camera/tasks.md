## 1. Orbital Animation

- [ ] 1.1 Create `useWinAnimation` composable for camera orbit logic
- [ ] 1.2 Implement gentle circular orbit around winning place coordinates
- [ ] 1.3 Use `requestAnimationFrame` for smooth animation
- [ ] 1.4 Set appropriate orbit radius and speed

## 2. Zoom and Framing

- [ ] 2.1 Calculate optimal zoom level based on place polygon size
- [ ] 2.2 Transition camera smoothly to win position
- [ ] 2.3 Handle places without polygon (use default zoom)

## 3. Visual Effects

- [ ] 3.1 Add glow effect to winning marker (CSS filter or deck.gl)
- [ ] 3.2 Implement pulse animation on win
- [ ] 3.3 Different styling for give-up state (muted vs celebratory)

## 4. Integration

- [ ] 4.1 Trigger animation when game status changes to 'won'
- [ ] 4.2 Stop animation when user navigates away
- [ ] 4.3 Provide option to skip/stop animation

## 5. Testing

- [ ] 5.1 Visual test: camera orbits correctly on win
- [ ] 5.2 E2E test: win state triggers animation
- [ ] 5.3 Test animation cleanup on navigation
