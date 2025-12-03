## ADDED Requirements

### Requirement: Standardized Data Fetching

The system SHALL use TanStack Query for all server data fetching.

#### Scenario: Fetching places list

- **WHEN** the places list is needed
- **THEN** `useQuery` is used with a `['places']` key
- **AND** duplicate requests are automatically deduplicated
- **AND** data is cached for subsequent access

#### Scenario: Stale data refetching

- **WHEN** cached data becomes stale
- **AND** the component using it is mounted
- **THEN** a background refetch occurs
- **AND** UI updates when fresh data arrives

#### Scenario: Loading and error states

- **WHEN** a query is in flight
- **THEN** `isLoading` is true
- **WHEN** a query fails
- **THEN** `error` contains the error details

### Requirement: Query DevTools

The system SHALL include TanStack Query DevTools in development mode.

#### Scenario: Development debugging

- **WHEN** running in development mode
- **THEN** Query DevTools are available
- **AND** cache state is inspectable
