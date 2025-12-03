# Change: Remove Legacy Algorithm Config Test Script

## Why

The `scripts/test-algorithm-configs.ts` script is a legacy, experimental tool for comparing embedding configurations. It is no longer part of the documented workflow, triggers lint errors due to unused variables, and risks confusion for contributors.

## What Changes

- Remove `scripts/test-algorithm-configs.ts` from the repository.
- Update any references in docs or scripts to avoid suggesting this workflow.
- Ensure the algorithm and evaluation workflow is documented in the specs instead.

## Impact

- Affected specs: `algorithm`, `operations`.
- Affected code: `scripts/test-algorithm-configs.ts` and any references to it.
- Simplifies the codebase and eliminates related lint errors.
