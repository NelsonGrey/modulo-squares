# Cost-Effective CI/CD Testing Strategy

This guide explains how to test and develop your CI/CD pipelines without consuming expensive GitHub Actions minutes.

## 🎯 Problem

GitHub Actions minutes are limited and costly. Testing workflows by pushing commits consumes these minutes rapidly, leaving none for actual deployments.

## 💡 Solution: Local-First Testing

### 1. Local Testing with Scripts

Use the provided scripts to test your entire pipeline locally:

```bash
# Test the full CI/CD pipeline locally
./scripts/dry-run-pipeline.sh development

# Test with act (GitHub Actions simulation)
./scripts/test-cicd-local.sh development true ci-cd-pipeline

# Test specific components
./scripts/test-cicd-local.sh development true android-distribution
```

### 2. Dry-Run Mode in Workflows

All workflows now support dry-run mode that skips expensive operations:

#### Automatic Dry-Run Triggers
- Include `[DRY-RUN]` or `[SKIP-DEPLOY]` in commit messages
- Example: `git commit -m "Update config [DRY-RUN]"`

#### Manual Dry-Run Testing
- Use workflow dispatch with "dry_run: true"
- Tests the entire pipeline without actual deployments

### 3. Local Firebase CLI Testing

Test Firebase operations locally before pushing:

```bash
# Check Firebase authentication
firebase projects:list

# Test project access
firebase use modulo-squares-dev
firebase deploy --only hosting:website --dry-run
```

## 🛠️ Testing Workflow

### Phase 1: Local Development
1. Make code changes
2. Test locally with `./scripts/dry-run-pipeline.sh`
3. Fix any issues found

### Phase 2: act Simulation
1. Run `act` to simulate GitHub Actions locally
2. Verify workflow logic without consuming minutes
3. Test different environments and configurations

### Phase 3: Dry-Run on GitHub
1. Push with `[DRY-RUN]` in commit message
2. Verify workflow runs correctly (consumes minutes but no deployment)
3. Check logs and fix any issues

### Phase 4: Live Deployment
1. Push without dry-run flags
2. Full deployment executes
3. Monitor results

## 📊 Cost Savings

| Method | Actions Minutes Used | Deployment Cost | Use Case |
|--------|---------------------|----------------|----------|
| Local Scripts | 0 | $0 | Development testing |
| act CLI | 0 | $0 | Workflow logic testing |
| Dry-Run Push | Yes (reduced) | $0 | Integration testing |
| Live Push | Yes | Full cost | Production deployment |

## 🏃 Quick Commands

```bash
# Local pipeline test
./scripts/dry-run-pipeline.sh development

# act workflow test
./scripts/test-cicd-local.sh development true ci-cd-pipeline

# Dry-run commit
git commit -m "Update feature [DRY-RUN]"

# Live deployment
git commit -m "Deploy feature"
```

## 🔧 Setup Requirements

1. **act CLI**: `brew install act`
2. **Firebase CLI**: `npm install -g firebase-tools`
3. **Flutter SDK**: Install from flutter.dev
4. **Local secrets**: Create `.env.local` with test values

## 📝 Best Practices

- **Test locally first**: Always run local tests before pushing
- **Use dry-run commits**: Include `[DRY-RUN]` for integration testing
- **Batch changes**: Group multiple changes in single commits
- **Monitor usage**: Check GitHub Actions usage regularly
- **Reserve minutes**: Save Actions minutes for actual deployments

## 🚨 Emergency Cost Control

### Conservative Workflow Triggers
- **Automatic deployment**: Only on `main` and `staging` branches
- **Development branch**: No automatic triggers (use manual workflow dispatch)
- **Safe commits**: Use `./scripts/safe-commit.sh` to avoid accidental triggers

### Workflow Trigger Summary
| Branch | Push Trigger | Actions Consumed | Use Case |
|--------|-------------|------------------|----------|
| `main` | ✅ Automatic | Full deployment | Production releases |
| `staging` | ✅ Automatic | Full deployment | Staging releases |
| `develop` | ❌ Manual only | Controlled testing | Development work |

### Safe Development Workflow
```bash
# 1. Test locally (0 Actions minutes)
./scripts/dry-run-pipeline.sh development

# 2. Safe commit (no automatic triggers)
./scripts/safe-commit.sh  # Choose option 2 or 4

# 3. Manual testing when ready (controlled Actions usage)
# Go to GitHub Actions → CI/CD Pipeline → Run workflow
# Select dry_run: true for testing without deployment

# 4. Production deployment only when ready
git push origin main  # Triggers full deployment
```

## 📚 Additional Resources

- [act CLI Documentation](https://github.com/nektos/act)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [GitHub Actions Billing](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions)