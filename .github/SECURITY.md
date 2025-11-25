# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project:

1. **DO NOT** open a public GitHub issue
2. Use [GitHub Security Advisories](../../security/advisories/new) to report privately
3. Provide steps to reproduce (if applicable)
4. Allow up to 48 hours for initial response

We take all security reports seriously and will acknowledge receipt within 48 hours.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

This project is in active development. Security updates are applied to the main branch.

## Security Measures

### Authentication & Authorization

- Supabase Authentication for user management
- Row Level Security (RLS) policies on all database tables
- SECURITY DEFINER functions validate auth.uid()
- Anonymous and registered user support with proper isolation

### Data Protection

- All sensitive credentials stored as environment variables
- API keys stored in Supabase Vault (never in database)
- `.env` files excluded from version control
- SQL injection protection via parameterized queries
- XSS protection via Vue 3 template escaping

### Input Validation

- Description length limits enforced (max 200 characters)
- Prompt injection pattern detection
- Language code format validation
- All validation in PostgreSQL (single source of truth)

### Rate Limiting

- Database-enforced per-user rate limits
- `start_game`: 10 per minute
- `play_turn`: 60 per minute
- `submit_place`: 10 per minute

### Automated Security Scanning

- **CodeQL** - Code vulnerability scanning
- **Semgrep** - Static security analysis
- **Dependabot** - Dependency vulnerability alerts
- **TruffleHog** - Secret detection in commits
- **OSSF Scorecard** - Security best practices

## Public vs Private Keys

### Safe to Expose (Protected by RLS)

- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Anonymous access key

### Never Expose

- `SUPABASE_SERVICE_KEY` - Bypasses RLS
- `SUPABASE_DB_PASSWORD` - Database password
- LLM/Embedding provider API keys

## Additional Resources

- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Vue.js Security Best Practices](https://vuejs.org/guide/best-practices/security.html)
