## ADDED Requirements

### Requirement: Memory Safety and Lifecycle Management

The system SHALL ensure all event listeners, timers, and subscriptions are properly cleaned up when components unmount.

#### Scenario: Map event listener cleanup

- **WHEN** a component with map event listeners unmounts
- **THEN** all listeners registered via `map.on()` are removed via `map.off()`
- **AND** no stale callbacks fire after unmount

#### Scenario: Timer cleanup

- **WHEN** a component with `setTimeout` or `setInterval` unmounts
- **THEN** pending timers are cleared via `clearTimeout`/`clearInterval`
- **AND** no callbacks fire after unmount

#### Scenario: Animation frame cleanup

- **WHEN** a component using `requestAnimationFrame` unmounts or aborts
- **THEN** pending animation frames are cancelled via `cancelAnimationFrame`

#### Scenario: Supabase subscription cleanup

- **WHEN** a store with auth state change subscription is disposed
- **THEN** the subscription is unsubscribed
- **AND** no stale callbacks fire

#### Scenario: Async operation safety

- **WHEN** an async operation completes after component unmount
- **THEN** refs are not updated (mounted check prevents update)
- **AND** no errors are thrown

### Requirement: Global Error Handling

The system SHALL provide centralized error handling with user feedback.

#### Scenario: Uncaught Vue errors

- **WHEN** an uncaught error occurs in a Vue component
- **THEN** `app.config.errorHandler` logs the error with context
- **AND** a user-friendly toast notification is shown
- **AND** the app remains functional (no white screen)

#### Scenario: API error transformation

- **WHEN** a Supabase API call fails
- **THEN** the raw error is transformed to `ApiError` with proper code
- **AND** the error is surfaced to the calling code

#### Scenario: User feedback on operation failure

- **WHEN** a user-initiated operation fails (start game, answer, submit)
- **THEN** a toast notification shows a localized error message
- **AND** the UI state allows retry

### Requirement: Type Safety Standards

The system SHALL maintain strict type safety without escape hatches.

#### Scenario: No any in application code

- **WHEN** the codebase is type-checked
- **THEN** zero `any` types exist in `src/` (excluding generated files)
- **AND** zero `eslint-disable` comments for type-related rules exist

#### Scenario: Explicit function return types

- **WHEN** a function is exported from a module
- **THEN** it has an explicit return type annotation
- **AND** the return type accurately reflects all return paths

#### Scenario: Composable return interfaces

- **WHEN** a composable function is defined
- **THEN** its return value is typed with a named interface
- **AND** the interface documents all exposed refs, computed, and functions

#### Scenario: Non-null assertions replaced

- **WHEN** accessing a potentially null/undefined value
- **THEN** proper type guards or optional chaining is used
- **AND** no non-null assertion operator (`!`) is used without prior narrowing

### Requirement: GeoJSON Type Definitions

The system SHALL use proper type definitions for geographic data.

#### Scenario: Geometry field typing

- **WHEN** a component or composable handles place geometry
- **THEN** it uses `GeoJSONGeometry` union type (Point | Polygon | MultiPolygon)
- **AND** not `any` or `unknown`

#### Scenario: Coordinate typing

- **WHEN** coordinates are processed
- **THEN** they are typed as `[number, number]` for points
- **AND** as `number[][]` for polygon rings
- **AND** as `number[][][]` for multi-polygon coordinates

### Requirement: Accessibility Compliance

The system SHALL be accessible to users with disabilities per WCAG 2.1 AA.

#### Scenario: Keyboard navigation

- **WHEN** a user navigates via keyboard (Tab, Enter, Space, Arrows)
- **THEN** all interactive elements are reachable
- **AND** focus indicators are visible
- **AND** activation works with Enter/Space

#### Scenario: ARIA labels

- **WHEN** an interactive element lacks visible text (icon buttons, etc.)
- **THEN** it has an `aria-label` attribute with descriptive text
- **AND** the label is internationalized

#### Scenario: Form accessibility

- **WHEN** a form input is rendered
- **THEN** it is associated with a label via `for`/`id` or `aria-label`
- **AND** error states are announced to screen readers

#### Scenario: Screen reader text

- **WHEN** sr-only text is used for screen readers
- **THEN** the text is internationalized (not hardcoded English)

#### Scenario: Focus management

- **WHEN** content changes dynamically (game state, dialog open)
- **THEN** focus moves to the new content appropriately
- **AND** screen readers announce the change

### Requirement: Complete Internationalization

The system SHALL have complete i18n coverage with no hardcoded user-facing strings.

#### Scenario: No hardcoded strings

- **WHEN** user-facing text is rendered
- **THEN** it comes from translation files via `t()` function
- **AND** no quoted strings exist in templates for user-visible text

#### Scenario: ICU MessageFormat pluralization

- **WHEN** pluralized text is rendered
- **THEN** it uses ICU MessageFormat syntax: `{count, plural, one{...} other{...}}`
- **AND** not legacy vue-i18n pipe syntax

#### Scenario: Placeholder internationalization

- **WHEN** form placeholders are rendered
- **THEN** they use translation keys
- **AND** are translated in all supported locales

## MODIFIED Requirements

### Requirement: Store Error Nullability Convention

The system SHALL use a consistent nullability convention for error state in frontend stores and composables.

#### Scenario: Error state type

- **WHEN** defining error refs in stores or composables
- **THEN** they use null as the "no error" value (e.g., `Ref<string | null>`) rather than undefined.

#### Scenario: Error reset behavior

- **WHEN** a previously errored operation later succeeds
- **THEN** the corresponding error state is reset to null.

#### Scenario: Test expectations

- **WHEN** running unit tests for stores and composables with error state
- **THEN** tests expect null for empty error state and match the standardized nullability convention.

#### Scenario: All stores have error state

- **WHEN** a store performs async operations
- **THEN** it exposes an `error` ref for operation failures
- **AND** the error ref is set on failure and cleared on success
