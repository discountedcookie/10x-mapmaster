## ADDED Requirements

### Requirement: Test Organization

Database tests SHALL be organized by domain, mirroring the `supabase/db/` directory structure.

#### Scenario: Test file naming convention

- **WHEN** creating a new database test file
- **THEN** the file name SHALL follow the pattern `test_{category}_{domain}.sql`
- **AND** `{category}` SHALL be one of: `tables`, `views`, `functions`, `schema`
- **AND** `{domain}` SHALL match the corresponding source file or directory name

#### Scenario: Test file contents

- **WHEN** a domain test file is created
- **THEN** it SHALL contain all tests for that domain including:
  - Schema validation (table/columns exist, correct types)
  - RLS policy tests (if applicable)
  - Behavioral tests (if applicable)

#### Scenario: Test discoverability

- **WHEN** a developer needs to find tests for a specific domain
- **THEN** they SHALL locate the test file by matching the domain name
- **AND** alphabetical sorting SHALL group files by category (tables, views, functions)
