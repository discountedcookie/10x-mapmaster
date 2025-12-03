## ADDED Requirements

### Requirement: No Escape Hatches

The system SHALL NOT use `any`, `@ts-ignore`, or `eslint-disable` for type-related rules except in generated code or third-party type definition gaps.

#### Scenario: Supabase RPC calls

- **WHEN** calling a Supabase RPC function
- **THEN** the call is properly typed with generics
- **AND** no `as any` cast is needed

#### Scenario: Store data access

- **WHEN** accessing store data in components
- **THEN** the data types flow correctly
- **AND** no `as unknown as` casts are needed

#### Scenario: Map library integration

- **WHEN** using MapLibre GL JS
- **THEN** event handlers and data are properly typed
- **AND** type definitions are provided for custom structures
