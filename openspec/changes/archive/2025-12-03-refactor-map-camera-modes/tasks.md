## 1. Foundation - Shared Composables

- [x] 1.1 Create `useZoomPitchCorrelation.ts` - interpolate pitch from zoom level (0° at zoom≤2, 55° at zoom≥12)
- [x] 1.2 Create `usePlacePresentation.ts` - extract rotation logic from PlaceView into reusable composable
- [x] 1.3 Add interaction mode config to `useMapCamera.ts` - support 'full', 'zoom-only', 'none' modes
- [x] 1.4 Add `onUserInteraction` callback to `useMapCamera.ts` for views to react to user input

## 2. Place Presentation Mode

- [x] 2.1 Refactor PlaceView to use `usePlacePresentation` instead of inline rotation
- [x] 2.2 Add zoom-pitch correlation to PlaceView - pitch adjusts smoothly when user zooms
- [x] 2.3 Add smart reset behavior - when user pans away, reset pitch to 0° and rotation to north
- [x] 2.4 Keep existing out-of-bounds detection and URL redirect to home

## 3. Game View Win State

- [x] 3.1 Add `usePlacePresentation` to GameView for win state (isWon)
- [x] 3.2 Add `usePlacePresentation` to GameView for submission pending state
- [x] 3.3 Configure interaction mode as 'zoom-only' for game presentation (no pan, no rotation stop)
- [x] 3.4 Add zoom-pitch correlation to game presentation mode

## 4. Home View Improvements

- [x] 4.1 Add smart resume after user pan-away - after 5s idle, resume place rotation
- [x] 4.2 Ensure interaction listeners properly handle all input types (mouse, touch, wheel)
- [ ] 4.3 Test cinematic intro still works on fresh page load

## 5. Testing and Polish

- [ ] 5.1 Test view transitions: Home → PlaceView → Home (camera state preservation)
- [ ] 5.2 Test view transitions: Home → GameView → Win → Home
- [ ] 5.3 Test zoom-pitch correlation feels natural at all zoom levels
- [ ] 5.4 Test mobile touch interactions work correctly
- [ ] 5.5 Verify no regressions in existing functionality
