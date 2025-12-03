## 1. Confirm Obsolescence

- [ ] 1.1 Search the repo for `test-algorithm-configs` to confirm it is not wired into `package.json` scripts or referenced in docs.
- [ ] 1.2 Verify that current algorithm evaluation approach (if any) is captured in `openspec/specs/algorithm/spec.md` or other docs.

## 2. Remove Script

- [ ] 2.1 Delete `scripts/test-algorithm-configs.ts`.
- [ ] 2.2 Run `bun run lint` to confirm related lint errors are resolved.

## 3. Documentation

- [ ] 3.1 Update any documentation that referenced this script to point to the current evaluation/testing process, or remove the reference entirely.
