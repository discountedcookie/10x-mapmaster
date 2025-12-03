## 1. i18n Types

- [x] 1.1 Review current vue-i18n module augmentation and error (`src/i18n/types.ts`).
- [x] 1.2 Update the vue-i18n module declaration so that `MessageSchema` is wired in without redefining `DefineLocaleMessage` in a conflicting way.
- [x] 1.3 Run `bun run type-check` to confirm all i18n-related TypeScript errors are resolved.

## 2. Locale Codes

- [x] 2.1 Decide and document that supported locales are `en`, `es`, and `pl` (short codes).
- [x] 2.2 Update `src/i18n/index.ts` to use `en`/`es`/`pl` for `locale`, `fallbackLocale`, `messages`, and available locale arrays.
- [x] 2.3 Add mapping logic from browser locale (e.g., `en-US`) to short codes where appropriate.
- [x] 2.4 Update `src/__tests__/i18n/index.spec.ts` to expect `en`/`es`/`pl` and correct fallback behavior.
- [x] 2.5 Update any docs/specs that explicitly mention `en-US`/`es-ES`/`pl-PL` so they match the short-code convention.

## 3. Verification

- [x] 3.1 Run `bun run type-check`.
- [x] 3.2 Run `bun run test:unit -- src/__tests__/i18n/index.spec.ts`.
- [x] 3.3 Document any remaining i18n-related warnings as acceptable or schedule follow-up work if needed.

### Notes

The vue-i18n warning `[intlify] This project is using Custom Message Compiler, which is an experimental feature.` is expected behavior since we use ICU MessageFormat via a custom message compiler. This is intentional and documented.
