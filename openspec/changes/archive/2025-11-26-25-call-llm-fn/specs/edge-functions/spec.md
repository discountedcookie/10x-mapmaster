## ADDED Requirements

### Requirement: call-llm Edge Function

The system SHALL provide an edge function to call LLMs for text generation with configurable providers.

#### Scenario: Successful LLM call

- **WHEN** called with valid parameters (model, temperature, max_tokens, prompt)
- **THEN** it returns generated text and hides provider secrets

#### Scenario: Error handling

- **WHEN** provider or input errors occur
- **THEN** standardized errors are returned with no sensitive data leaked

#### Scenario: Configuration

- **WHEN** changing providers
- **THEN** configuration/env selects providers without code changes
