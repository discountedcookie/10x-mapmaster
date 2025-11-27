# Change: Add Security Pipeline

## Why

Run automated security and quality scans to detect vulnerabilities and issues early.

## What Changes

- Enable CodeQL, Semgrep, Trufflehog, and OSSF Scorecard in CI
- Configure scopes and schedules

## Impact

- Affected specs: operations
- Affected code: .github/workflows/security.yml (or equivalents)
