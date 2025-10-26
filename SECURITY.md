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

## Disclosure Policy

When a security vulnerability is confirmed:

1. We will acknowledge the report and work on a fix
2. A security advisory will be published after the fix is ready
3. Credit will be given to the reporter (unless anonymity is requested)
4. Details will be disclosed after sufficient time for users to update

Thank you for helping keep 10x-mapmaster secure!
