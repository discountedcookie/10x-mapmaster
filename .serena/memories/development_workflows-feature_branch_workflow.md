### Feature Development Workflow
```bash
# 1. Create feature branch
git checkout -b feature/<name>

# 2. Develop with local DB
npx supabase db reset  # SAFE

# 3. Pre-commit check
/pre_commit_check  # Cursor command

# 4. Commit
git commit -m "feat(scope): description"

# 5. Push and PR
git push origin feature/<name>

# 6. PR review
/review_code_changes  # Cursor command

# 7. Merge after approval
git checkout main
git merge feature/<name>
```
