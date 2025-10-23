## Modern Authentication Flow (October 21, 2025)

**Decision**: Replace modal-based auth with dedicated login/signup pages using modern form patterns.

**Implementation**:
1. **Dedicated Pages**: Separate `/login` and `/signup` routes
   - Better UX than modal interruption
   - Cleaner routing and state management
   - Follows modern SPA patterns

2. **Form Validation**: vee-validate + Zod for type-safe validation
   - Consistent with shadcn-vue ecosystem
   - Better TypeScript integration
   - Real-time validation feedback
   - Password confirmation on signup

3. **Email Verification**: Required before first login
   - `enable_confirmations = true` in Supabase
   - Clear messaging to check email after signup
   - Helpful error messages if trying to login without verification
   - Environment-aware redirect URLs (localhost:5173 for dev)

4. **Router Guards**: Navigation guards protect routes
   - `/game` requires authentication
   - `/login` and `/signup` redirect authenticated users to `/game`
   - Centralized auth logic (no per-component checks)

5. **Auth Store Improvements**: Better error handling
   - Specific error messages for common cases (email not confirmed, invalid credentials)
   - User-friendly wording instead of raw Supabase errors

**Rationale**:
- Dedicated pages provide better UX than modal interruption
- shadcn-vue form patterns match rest of application
- Email verification adds security layer
- Router guards centralize auth logic (DRY principle)
- Follows Vue Router best practices
