## ADDED Requirements

### Requirement: Geographic Candidate Filtering

The system SHALL filter candidate places by geographic regions for geographic questions.

#### Scenario: Region inclusion

- **WHEN** an answer affirms a region
- **THEN** candidates are filtered to places whose geometry is within the region

#### Scenario: Region exclusion

- **WHEN** an answer denies a region
- **THEN** candidates exclude places contained in that region

#### Scenario: Performance support

- **WHEN** executing filters
- **THEN** appropriate GIST indexes on place geometry are used
