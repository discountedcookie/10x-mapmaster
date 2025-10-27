# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

**Note:** This project is currently in pre-1.0 development. Security updates are applied to the main branch only.

## Reporting a Vulnerability

We take the security of 10x-mapmaster seriously. If you discover a security vulnerability, please follow these steps:

### GitHub Security Advisories (Preferred)

1. Navigate to the [Security Advisories](https://github.com/discountedcookie/10x-mapmaster/security/advisories) page
2. Click "Report a vulnerability"
3. Fill out the advisory form with details about the vulnerability
4. Submit the report

### Email Report (Alternative)

If you prefer not to use GitHub Security Advisories, you can email security reports to the repository maintainers through GitHub.

### What to Include

Please provide the following information in your report:

- **Description**: Clear description of the vulnerability
- **Impact**: What an attacker could do with this vulnerability
- **Reproduction**: Step-by-step instructions to reproduce the issue
- **Affected versions**: Which versions are impacted
- **Suggested fix**: If you have recommendations for addressing the issue

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days with assessment and action plan
- **Resolution**: Security patches are prioritized and released as soon as possible

## Security Measures

This repository implements multiple layers of security:

### Automated Scanning

- **CodeQL Analysis**: Continuous code scanning for vulnerabilities
- **Semgrep**: Security-focused static analysis for TypeScript/Vue
- **Dependency Scanning**: Automated vulnerability detection via Dependabot
- **Secret Detection**: TruffleHog scans for exposed credentials
- **OSSF Scorecard**: Security best practices monitoring

### Development Practices

- All dependencies are regularly updated and audited
- Security patches are applied promptly
- Code changes require review before merging
- Continuous integration runs security scans on all PRs

## Latest Security Scan Results

**Last Updated:** October 27, 2025
**Latest Commit:** 2f71cb2 (feat: Add GitHub OAuth Login #10)

### Semgrep SAST (Static Application Security Testing)

**Status:** ✅ **CLEAN** - No vulnerabilities detected

- **Scan Date:** 2025-10-27
- **Semgrep Version:** 1.140.0
- **Files Scanned:** 9 core application files (including new OAuth implementation)
- **Vulnerabilities Found:** 0
- **Severity Breakdown:** None

**Scanned Components:**
- Authentication system with GitHub OAuth (`src/stores/auth.ts`)
- Login page (`src/views/LoginView.vue`)
- Signup page (`src/views/SignupView.vue`)
- Database client (`src/lib/supabase.ts`)
- Game state management (`src/stores/game.ts`)
- AI embeddings (`src/composables/useEmbeddings.ts`)
- Statistics calculations (`src/composables/useStatistics.ts`)
- Router configuration (`src/router/index.ts`)
- Application entry point (`src/main.ts`)

### Semgrep SCA (Supply Chain Analysis)

**Status:** ✅ **CLEAN** - No vulnerable dependencies

- **Scan Date:** 2025-10-27
- **Dependencies Analyzed:** 883 packages
- **Ecosystem:** npm (package-lock.json)
- **Vulnerabilities Found:** 0
- **Resolution Status:** Successful

### OAuth Security Review

**GitHub OAuth Implementation:** ✅ **SECURE**

The OAuth login feature was manually reviewed for security best practices:

- ✅ **OAuth Flow:** Uses Supabase's built-in OAuth provider (no custom implementation)
- ✅ **Session Management:** Handles invalid sessions gracefully with automatic cleanup
- ✅ **Input Validation:** Email and password validation with Zod schema
- ✅ **XSS Protection:** Vue template binding auto-escapes all output, no innerHTML usage
- ✅ **Error Handling:** Specific user-friendly errors without leaking sensitive info
- ✅ **Redirect Security:** Internal redirects only via Vue Router, no open redirect vulnerability

### Summary

All security scans show a clean security posture with:
- ✅ No code vulnerabilities (XSS, SQL injection, authentication flaws, etc.)
- ✅ No vulnerable third-party dependencies
- ✅ Clean supply chain security
- ✅ OAuth implementation follows security best practices

**Previous Scan:** October 21, 2025

## Disclosure Policy

When a security vulnerability is confirmed:

1. We will acknowledge the report and work on a fix
2. A security advisory will be published after the fix is ready
3. Credit will be given to the reporter (unless anonymity is requested)
4. Details will be disclosed after sufficient time for users to update

Thank you for helping keep 10x-mapmaster secure!
