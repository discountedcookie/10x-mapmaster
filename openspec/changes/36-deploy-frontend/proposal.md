# Change: Add Deploy Frontend

## Why

Automate frontend deployment to GitHub Pages after tests pass.

## What Changes

- Add CI/CD workflow to build and deploy static frontend artifacts to Pages
- Wire dependencies on test jobs

## Impact

- Affected specs: operations
- Affected code: .github/workflows/pages.yml (or similar), build config
