# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it by:

1. **DO NOT** open a public GitHub issue
2. Email the maintainers directly with details
3. Provide steps to reproduce (if applicable)
4. Allow up to 48 hours for initial response

We take all security reports seriously and will acknowledge receipt within 48 hours.

## Security Measures

This project implements the following security best practices:

### Authentication & Authorization
- ✅ Supabase Authentication for user management
- ✅ Row Level Security (RLS) policies on all database tables
- ✅ Session management via secure HTTP-only cookies
- ✅ No passwords stored in frontend code

### Data Protection
- ✅ All sensitive credentials stored as environment variables
- ✅ No hardcoded secrets in codebase
- ✅ `.env` files excluded from version control
- ✅ SQL injection protection via Supabase query builder
- ✅ XSS protection via Vue 3 template escaping

### API Security
- ✅ Rate limiting on embedding generation endpoints
- ✅ Input validation on client and server
- ✅ CORS properly configured for Edge Functions
- ✅ Authorization headers required for API calls

### Dependencies
- ✅ Regular dependency audits via `npm audit`
- ✅ Automated Dependabot security updates (GitHub)
- ✅ All dependencies kept up-to-date

## Security Checklist for Deployment

Before deploying to production:

- [ ] All dependencies audited (`npm audit` returns 0 vulnerabilities)
- [ ] Environment variables properly configured
- [ ] `.env` files not committed to repository
- [ ] GitHub secret scanning enabled
- [ ] Dependabot alerts enabled
- [ ] Branch protection rules configured
- [ ] Supabase RLS policies tested and verified
- [ ] Rate limiting verified on production endpoints

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.x.x   | :white_check_mark: |

## Known Security Considerations

### Public API Keys (Safe)
This project uses Supabase anon keys which are safe to expose publicly:
- `VITE_SUPABASE_URL` - Safe (protected by RLS)
- `VITE_SUPABASE_ANON_KEY` - Safe (protected by RLS)

These keys only provide access to data allowed by Row Level Security policies.

### Private Keys (Never Expose)
The following should NEVER be committed or exposed:
- `SUPABASE_DB_PASSWORD` - Database password
- `SUPABASE_ACCESS_TOKEN` - Supabase API access token
- `SUPABASE_SERVICE_KEY` - Bypasses RLS (admin access)

## Security Audit History

- **2025-10-21**: Initial security audit completed using Semgrep
  - No critical vulnerabilities found
  - 1 moderate Vite vulnerability fixed
  - All security best practices verified

## Additional Resources

- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Vue.js Security Best Practices](https://vuejs.org/guide/best-practices/security.html)

