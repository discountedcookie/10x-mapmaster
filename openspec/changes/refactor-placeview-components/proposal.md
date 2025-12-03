# Change: Refactor PlaceView into Components

## Why

`PlaceView.vue` is 560 lines - nearly 3x the 200-line project limit. It contains:

- ~100 lines of duplicate template code for mobile/desktop card layouts
- Mixed concerns (map setup, camera control, UI state, data fetching)
- Complex conditional rendering that could be simpler components

This makes the file hard to navigate, test, and maintain.

## What Changes

- Extract shared place card content into `PlaceCard.vue` component
- Use CSS-only responsive approach OR single template with conditional classes
- Extract map setup logic to composable if not already
- Target: PlaceView.vue under 200 lines

## Impact

- Affected specs: `frontend` (Component structure)
- Affected code:
  - `src/views/PlaceView.vue` - Refactor
  - `src/components/place/PlaceCard.vue` - New component
  - `src/components/place/PlaceDetails.vue` - New component (optional)
