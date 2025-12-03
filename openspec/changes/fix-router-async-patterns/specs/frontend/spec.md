## MODIFIED Requirements

### Requirement: Route Lazy Loading

The system SHALL lazy-load view components to reduce initial bundle size.

#### Scenario: Initial page load

- **WHEN** the application loads
- **THEN** only the requested route's component is loaded
- **AND** other view components are loaded on demand

### Requirement: Auth-Aware Navigation

The system SHALL wait for auth initialization before evaluating route guards.

#### Scenario: Navigation during auth initialization

- **WHEN** a user navigates to a protected route
- **AND** auth state is still initializing
- **THEN** navigation waits for auth to complete (without polling)
- **AND** then evaluates the route guard

#### Scenario: Auth already initialized

- **WHEN** a user navigates to any route
- **AND** auth state is already initialized
- **THEN** navigation proceeds immediately
