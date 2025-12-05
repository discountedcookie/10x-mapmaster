## 1. Output Sanitization

- [ ] 1.1 Create `sanitizeOutput(text: string): string` utility in call-llm edge function
- [ ] 1.2 Implement HTML tag stripping (`<s>`, `</s>`, `<br>`, etc.)
- [ ] 1.3 Implement LLM artifact removal (`[OUT]`, `[INST]`, `<|im_start|>`, etc.)
- [ ] 1.4 Implement whitespace normalization (collapse multiple spaces/newlines)
- [ ] 1.5 Apply sanitization to question generation responses
- [ ] 1.6 Apply sanitization to trait clause text

## 2. Update Trait Extraction Prompt

- [ ] 2.1 Add instruction to reject fantastical/unverifiable claims
- [ ] 2.2 Add instruction to only include facts that can be verified
- [ ] 2.3 Add examples of claims to reject (aliens, magic, conspiracy)

## 3. Trait Quality Validation

- [ ] 3.1 Add length validation (min 5, max 200 characters)
- [ ] 3.2 Add generic word filter (reject traits that are only adjectives)
- [ ] 3.3 Log rejected traits for monitoring

## 4. Tests

- [ ] 4.1 Test: HTML tags are stripped from question text
- [ ] 4.2 Test: LLM artifacts are removed from output
- [ ] 4.3 Test: Traits with fantastical claims are not extracted
- [ ] 4.4 Test: Short/long traits are rejected
- [ ] 4.5 Test: Valid factual traits pass through
