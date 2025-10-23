### Daily Development
```bash
npm run dev  # http://localhost:5173/10x-mapmaster/

# Database (local only - SAFE)
npx supabase db reset

# Quality checks
npm test           # Unit tests (10/10 passing)
npm run test:db    # Database tests (11/11 passing)
npm run test:e2e   # E2E tests
npm run type-check # ✅ Passing
npm run lint       # ✅ Passing

# Build
npm run build
```
