# Change: Fix i18n Types and Locale Codes

## Why

The current i18n setup causes a TypeScript compilation failure due to an incorrect vue-i18n module augmentation and uses `en-US`/`es-ES`/`pl-PL` locale codes, while the project should standardize on short codes `en`/`es`/`pl`. This breaks the build and causes tests to fail.

## What Changes

- Fix vue-i18n type augmentation so that `MessageSchema` integrates cleanly with vue-i18n without redefining `DefineLocaleMessage`.
- Standardize locale identifiers on `en`/`es`/`pl` throughout the frontend (i18n config, tests, and any docs mentioning locales).
- Align unit tests with the new locale identifiers and ensure they reflect actual configured messages and fallback behavior.

## Impact

- Affected specs: `frontend`, `game-core` (localization behavior).
- Affected code: `src/i18n/index.ts`, `src/i18n/types.ts`, `src/__tests__/i18n/index.spec.ts`, and any other locale-related tests or docs.
- Build will pass TypeScript checks again, and i18n tests will match the intended configuration.
