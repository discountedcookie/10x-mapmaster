# Quality & Security Tooling Setup Guide

This project uses 4 automated tools for quality assurance. All are fully configured and require no setup.

## ✅ Configured Tools

### 1. **Codecov** - Test Coverage
- **Status:** ✅ Configured (CODECOV_TOKEN added)
- **Runs:** Every push to main, PRs
- **Badge:** Shows in README
- **Dashboard:** https://codecov.io/gh/discountedcookie/10x-mapmaster

### 2. **Dependabot** - Dependency Updates
- **Status:** ✅ Auto-enabled
- **Runs:** Weekly on Mondays
- **Action:** Review and merge PRs automatically created
- **Config:** `.github/dependabot.yml`
  - Groups minor/patch updates together
  - Separate PRs for major updates
  - Updates npm packages and GitHub Actions

### 3. **Bundle Size Tracking**
- **Status:** ✅ Auto-enabled
- **Runs:** On pull requests
- **Action:** Automatically comments on PRs with bundle size changes
- **Threshold:** Alerts on changes >100 bytes
- **Tracks:** Gzipped JS and CSS files in `dist/assets/`

### 4. **OSSF Scorecard** - Security Best Practices
- **Status:** ✅ Auto-enabled
- **Runs:** Weekly on Saturdays + on main branch pushes
- **Badge:** Shows in README
- **Dashboard:** https://scorecard.dev/viewer/?uri=github.com/discountedcookie/10x-mapmaster
- **Results:** GitHub Security tab
- **Checks:** Security best practices (dependency pinning, branch protection, code review, etc.)

---

## Tool Matrix

| Tool | Purpose | Trigger | Setup Needed |
|------|---------|---------|--------------|
| Codecov | Coverage tracking | Push, PR | ✅ Done |
| Dependabot | Dependency updates | Weekly | ✅ Auto |
| Bundle Size | Bundle monitoring | PR | ✅ Auto |
| OSSF Scorecard | Security posture | Weekly, Push | ✅ Auto |

---

## Next Steps

1. **Monitor workflows** at https://github.com/discountedcookie/10x-mapmaster/actions
2. **Review Dependabot PRs** when created
3. **Check coverage trends** on Codecov dashboard

---

## Merging Dependabot PRs

When Dependabot creates PRs:
1. Check that CI passes (all tests green)
2. Review the changelog links in PR description
3. For minor/patch updates: Usually safe to merge
4. For major updates: Review breaking changes carefully

You can auto-merge safe updates by commenting `@dependabot merge` on the PR.
