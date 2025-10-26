# Quality & Security Tooling Setup Guide

This project uses 8 complementary tools for comprehensive quality assurance. Most are auto-configured, but some require one-time setup.

## ✅ Already Working (No Setup Required)

### 1. **Codecov** - Test Coverage
- **Status:** ✅ Configured (CODECOV_TOKEN added)
- **Runs:** Every push to main, PRs
- **Badge:** Shows in README

### 2. **Dependabot** - Dependency Updates
- **Status:** ✅ Auto-enabled on push
- **Runs:** Weekly on Mondays
- **Action:** Review and merge PRs automatically created

### 3. **Bundle Size Tracking**
- **Status:** ✅ Auto-enabled
- **Runs:** On PRs
- **Action:** Review size changes in PR comments

### 4. **Lighthouse CI** - Performance Audits
- **Status:** ✅ Auto-enabled
- **Runs:** On PRs and main pushes
- **Thresholds:**
  - Performance: 80%
  - Accessibility: 90%
  - Best Practices: 85%
  - SEO: 80%

### 5. **Release Please** - Automated Releases
- **Status:** ✅ Auto-enabled
- **Runs:** On main branch pushes
- **Action:** Merges release PRs when ready to release

### 6. **OSSF Scorecard** - Security Posture
- **Status:** ✅ Auto-enabled
- **Runs:** Weekly on Saturdays + on pushes
- **View:** GitHub Security tab

### 7. **Axe-core** - Accessibility Testing
- **Status:** ✅ Integrated in unit tests
- **Runs:** With `npm run test:unit`
- **Example:** `src/__tests__/components/accessibility.spec.ts`

---

## ⚙️ Requires Setup

### 8. **SonarCloud** - Code Quality Analysis

**Setup Steps:**

1. **Create SonarCloud Account**
   - Go to https://sonarcloud.io
   - Sign in with GitHub
   - Create organization: `discountedcookie`

2. **Import Repository**
   - Click "+ Analyze new project"
   - Select `10x-mapmaster`
   - Choose "With GitHub Actions"

3. **Add Secret to GitHub**
   - SonarCloud will show you a token
   - Go to GitHub repo → Settings → Secrets → Actions
   - Add new secret: `SONAR_TOKEN` = [your token]

4. **Verify Workflow**
   - Push a commit (or manually trigger workflow)
   - Check https://sonarcloud.io/dashboard?id=discountedcookie_10x-mapmaster

---

## Tool Matrix

| Tool | Purpose | Trigger | Setup Needed |
|------|---------|---------|--------------|
| Codecov | Coverage tracking | Push, PR | ✅ Done |
| Dependabot | Dependency updates | Weekly | ✅ Auto |
| Bundle Size | Bundle monitoring | PR | ✅ Auto |
| Lighthouse | Performance/A11y | Push, PR | ✅ Auto |
| SonarCloud | Code quality | Push, PR | ⚙️ **Required** |
| Release Please | Versioning | Push (main) | ✅ Auto |
| OSSF Scorecard | Security score | Weekly, Push | ✅ Auto |
| Axe-core | A11y tests | Unit tests | ✅ Done |

---

## Next Steps

1. **Setup SonarCloud** (see above)
2. **Monitor workflows** at https://github.com/discountedcookie/10x-mapmaster/actions
3. **Review first Dependabot PRs** (coming Monday)
4. **Check badges** in README once workflows complete

---

## Adding More Accessibility Tests

To test more components:

```typescript
import { axe } from '../setup'
import { mount } from '@vue/test-utils'
import YourComponent from '@/components/YourComponent.vue'

it('should not have accessibility violations', async () => {
  const wrapper = mount(YourComponent, { props: { /* ... */ } })
  const results = await axe(wrapper.element as HTMLElement)
  expect(results).toHaveNoViolations()
})
```

---

## Troubleshooting

**Bundle Size fails:** Check that build secrets (VITE_SUPABASE_*) are set in GitHub
**Lighthouse fails:** May need to adjust thresholds in `lighthouserc.json`
**SonarCloud fails:** Ensure SONAR_TOKEN secret is set correctly
**OSSF Scorecard low score:** Review security recommendations at https://scorecard.dev
