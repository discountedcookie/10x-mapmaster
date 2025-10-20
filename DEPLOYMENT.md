# Deployment Guide

This guide covers deploying the 10x-mapmaster application to production.

## Prerequisites

1. **Supabase Project**: Create a production project at [supabase.com](https://supabase.com)
2. **GitHub Repository**: Code must be pushed to GitHub
3. **GitHub Pages**: Enabled in repository settings

## GitHub Secrets Configuration

You need to add the following secrets to your GitHub repository:

### Navigate to Settings > Secrets and variables > Actions > New repository secret

#### Required Secrets:

1. **`SUPABASE_ACCESS_TOKEN`**
   - **What it is**: Personal access token for Supabase CLI operations
   - **Security Note**: ⚠️ This token gives access to **all projects** in your account
   - **How to get it**: https://supabase.com/dashboard/account/tokens
     - Click "Generate new token"
     - Give it a name (e.g., "GitHub Actions - 10x-mapmaster")
     - Copy the token immediately (shown only once)
   - **Best Practice**: Create a dedicated Supabase account for CI/CD with access only to this project
   - **Alternative**: If concerned about security, you can run migrations manually (see below)

2. **`SUPABASE_DB_PASSWORD`**
   - **What it is**: Your project's database password
   - **How to get it**: Project Settings > Database > Database password
   - **Note**: This is the password you set when creating the project

3. **`SUPABASE_PROJECT_ID`**
   - **What it is**: Your project reference ID (project-specific, safe to use)
   - **How to get it**: Project Settings > General > Reference ID
   - **Format**: Looks like `abcdefghijklmnop`

4. **`VITE_SUPABASE_URL`**
   - **What it is**: Your public Supabase project URL
   - **How to get it**: Project Settings > API > Project URL
   - **Format**: `https://your-project-ref.supabase.co`
   - **Security**: ✅ Safe to expose publicly

5. **`VITE_SUPABASE_ANON_KEY`**
   - **What it is**: Public anonymous key for frontend use
   - **How to get it**: Project Settings > API > Project API keys > anon public
   - **Security**: ✅ Safe to expose publicly (protected by RLS policies)

## How the Deployment Works

When you push to the `main` branch, the GitHub Actions workflow will:

1. **Migrate Database** (Job 1):
   - Checkout code
   - Install Supabase CLI
   - Link to your production Supabase project
   - Run all migrations from `supabase/migrations/` folder
   - This ensures your production database schema is up to date

2. **Build Frontend** (Job 2):
   - Runs after migrations complete successfully
   - Install dependencies
   - Build the Vite app with production Supabase credentials
   - Upload build artifacts

3. **Deploy to GitHub Pages** (Job 3):
   - Deploy the built app to GitHub Pages
   - Your app will be available at: `https://yourusername.github.io/10x-mapmaster/`

## Initial Production Setup

### 1. Create Production Supabase Project

```bash
# Create a new project at supabase.com
# Note the project reference ID and credentials
```

### 2. Configure GitHub Secrets

Add all four secrets listed above to your GitHub repository.

### 3. Update Local Environment (Optional)

If you want to test against production locally:

```bash
# Create .env.production.local (gitignored)
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 4. Push to Main

```bash
git add .
git commit -m "Configure production deployment"
git push origin main
```

The workflow will automatically:
- Run migrations on your production database
- Build the app with production credentials
- Deploy to GitHub Pages

## Security Considerations

### About SUPABASE_ACCESS_TOKEN

The `SUPABASE_ACCESS_TOKEN` is required for automated deployments but gives access to **all Supabase projects** in your account. Here are safer alternatives:

#### Option 1: Create a Dedicated CI/CD Account (Recommended)
1. Create a new Supabase account specifically for CI/CD
2. Add this account as a collaborator to only this project
3. Generate an access token from this account
4. Use this token in GitHub secrets

**Pros**: Limited blast radius if token is compromised
**Cons**: Requires managing an additional account

#### Option 2: Manual Migrations (Most Secure)
1. Remove the `migrate-database` job from the workflow
2. Run migrations manually before each deployment
3. Only use GitHub Actions for frontend deployment

**Pros**: No access token needed, complete control
**Cons**: Manual step required before each push to main

#### Option 3: Repository-Specific Deployment Keys
Supabase is working on project-scoped tokens. Check their docs for updates:
https://supabase.com/docs/guides/platform/access-control

## Manual Migration Commands

If you choose manual deployments or need to run migrations manually:

### Link to Production Project

```bash
# One-time setup (will prompt for access token)
supabase link --project-ref your-project-ref
```

### Push Migrations

```bash
# Push all migrations to production
supabase db push

# Or push with seed data
supabase db push --include-seed
```

### Generate Types from Production

```bash
# Update TypeScript types from production schema
npm run supabase:types:remote
```

## Disabling Automated Migrations

If you prefer manual migrations for security:

1. **Remove the migrate-database job** from [.github/workflows/deploy.yml](/.github/workflows/deploy.yml)
2. **Remove the `needs: migrate-database` line** from the build job
3. **Manually run migrations** before pushing to main:
   ```bash
   supabase link --project-ref your-project-ref
   supabase db push
   git push origin main
   ```

## Monitoring Deployments

1. **GitHub Actions**: Check the Actions tab in your repository
2. **Supabase Dashboard**: Monitor database changes in the Table Editor
3. **GitHub Pages**: Visit your site URL to verify deployment

## Rollback Strategy

If a migration causes issues:

1. **Via Supabase Dashboard**:
   - Go to Database > Migrations
   - View migration history
   - Manual rollback if needed

2. **Via CLI**:
   ```bash
   # Reset to a specific migration
   supabase db reset --version <migration-version>
   ```

## Production Database Seeding

⚠️ **Important**: The MVP includes seed data in migrations (questions and places). For production:

### Option 1: Keep Seed Data (Recommended for MVP)
- The migrations will automatically seed 5 questions and 20 places
- Good for testing and initial launch

### Option 2: Remove Seed Data (True Cold Start)
- Delete or comment out seed migrations:
  - `supabase/migrations/20250101000002_seed_questions.sql`
  - `supabase/migrations/20250101000003_seed_places.sql`
- Start with empty database
- Let users populate data through gameplay

## Environment Files Summary

```
.env.local               # Local Supabase (http://127.0.0.1:54321)
.env.production.local    # Production testing (gitignored)
GitHub Secrets           # Production deployment
```

## Troubleshooting

### Workflow Fails on Migration Step

- Check that `SUPABASE_ACCESS_TOKEN` is valid
- Verify `SUPABASE_PROJECT_REF` is correct
- Review migration files for SQL errors
- Check Supabase project logs

### Build Fails

- Ensure `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are set
- Check that all dependencies are in `package.json`
- Review build logs in GitHub Actions

### App Loads but Can't Connect to Database

- Verify Supabase credentials in GitHub secrets
- Check RLS policies are properly configured
- Ensure anon key has correct permissions

## Security Best Practices

### Secrets Classification

| Secret | Safe to Expose? | Scope | Notes |
|--------|----------------|-------|-------|
| `VITE_SUPABASE_ANON_KEY` | ✅ Yes | Public | Protected by RLS policies |
| `VITE_SUPABASE_URL` | ✅ Yes | Public | Project URL |
| `SUPABASE_PROJECT_ID` | ✅ Yes | Single Project | Just an identifier |
| `SUPABASE_DB_PASSWORD` | ❌ No | Single Project | Database access |
| `SUPABASE_ACCESS_TOKEN` | ❌ **NEVER** | **All Projects** | Full account access |

### Recommendations

1. **Never commit secrets** to git (use `.gitignore` for `.env` files)
2. **Use environment-specific accounts** for CI/CD when possible
3. **Rotate tokens regularly** if using personal access tokens
4. **Enable RLS policies** on all tables (already done in this project)
5. **Consider manual migrations** for production if security is a primary concern
6. **Use GitHub environment secrets** for additional protection (optional)

### What to Do If a Token is Compromised

**If `SUPABASE_ACCESS_TOKEN` is exposed:**
1. Immediately revoke the token at https://supabase.com/dashboard/account/tokens
2. Generate a new token
3. Update GitHub secrets
4. Review audit logs in Supabase dashboard

**If `SUPABASE_DB_PASSWORD` is exposed:**
1. Reset the database password in Project Settings
2. Update GitHub secrets
3. Update local `.env` files

## Next Steps After Deployment

1. Test the live application
2. Monitor error logs in Supabase Dashboard
3. Set up custom domain (optional)
4. Configure auth providers (email is already set up)
5. Set up monitoring/analytics (optional)
