## 1. Analyze Current Structure

- [ ] 1.1 Identify the duplicate mobile/desktop template sections
- [ ] 1.2 List all shared content between the two layouts
- [ ] 1.3 Identify layout-only differences (positioning, sizing)

## 2. Extract Place Card Component

- [ ] 2.1 Create `src/components/place/` directory
- [ ] 2.2 Create `PlaceCard.vue` with shared card content
- [ ] 2.3 Accept `variant` prop for 'desktop' | 'mobile' layout
- [ ] 2.4 Use CSS classes for layout differences, not template duplication

## 3. Extract Place Details Component

- [ ] 3.1 Create `PlaceDetails.vue` for the traits/description section
- [ ] 3.2 Move trait display logic to this component
- [ ] 3.3 Accept place data as props

## 4. Refactor PlaceView

- [ ] 4.1 Replace duplicate templates with `<PlaceCard>` components
- [ ] 4.2 Keep map setup and camera logic in view
- [ ] 4.3 Ensure view is under 200 lines

## 5. Verify

- [ ] 5.1 Run `bun run type-check` to ensure no type errors
- [ ] 5.2 Test responsive behavior on mobile and desktop
- [ ] 5.3 Verify PlaceView.vue line count is under 200
