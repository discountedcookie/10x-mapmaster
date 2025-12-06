## ADDED Requirements

### Requirement: LLM Output Sanitization

The system SHALL sanitize LLM-generated text to remove artifacts before returning to callers.

#### Scenario: HTML tag removal

- **WHEN** LLM output contains HTML tags (e.g., `<s>`, `</s>`, `<br>`)
- **THEN** tags are stripped from the output
- **AND** surrounding whitespace is normalized

#### Scenario: Common artifact patterns

- **WHEN** LLM output contains known artifact patterns:
  - `[OUT]`, `[/OUT]`, `[INST]`, `[/INST]`
  - `<|im_start|>`, `<|im_end|>`, `<|endoftext|>`
  - Multiple consecutive newlines or spaces
- **THEN** these patterns are removed or normalized

#### Scenario: Empty result handling

- **WHEN** sanitization results in empty or whitespace-only text
- **THEN** the fallback template is used instead
- **AND** the issue is logged for monitoring

### Requirement: Fact Quality Filtering

The system SHALL filter low-quality or unverifiable facts from trait extraction.

#### Scenario: Prompt-based filtering

- **WHEN** extracting traits from user descriptions
- **THEN** the LLM prompt instructs to reject claims that are:
  - Obviously false or fantastical (aliens, magic, conspiracy theories)
  - Unverifiable personal opinions without factual basis
  - Contradicting well-known facts about the place

#### Scenario: Trait quality validation

- **WHEN** processing extracted traits
- **THEN** traits shorter than 5 characters are rejected
- **AND** traits longer than 200 characters are rejected
- **AND** traits containing only generic words are rejected

## MODIFIED Requirements

### Requirement: call-llm Edge Function

The system SHALL provide an edge function to call LLMs for text generation and structured extraction with output sanitization.

#### Scenario: Successful LLM call

- **WHEN** called with valid parameters
- **THEN** it returns generated text or structured data
- **AND** text outputs are sanitized before returning

#### Scenario: Question generation

- **WHEN** called with `type: 'question_generation'`
- **THEN** it returns natural language question text
- **AND** the text is sanitized to remove HTML/artifacts

#### Scenario: Trait extraction

- **WHEN** called with `type: 'trait_extraction'`
- **THEN** it returns structured traits array
- **AND** clause text within traits is sanitized
- **AND** low-quality traits are filtered out
