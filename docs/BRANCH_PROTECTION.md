# Branch Protection Rules Setup

## Recommended Branch Protection Rules

Set up the following branch protection rules in your GitHub repository:

### Main Branch (`main`) - Production
**Settings → Branches → Add rule**
- **Branch name pattern**: `main`
- **Require a pull request before merging**
  - [x] Require approvals (1 reviewer)
  - [x] Dismiss stale pull request approvals when new commits are pushed
- **Require status checks to pass before merging**
  - [x] Require branches to be up to date before merging
  - [x] Status checks: `test`, `build-and-deploy`
- **Include administrators**
- **Restrict pushes that create matching branches**
- **Allow force pushes**: ❌ Disabled
- **Allow deletions**: ❌ Disabled

### Staging Branch (`staging`) - Pre-Production
**Settings → Branches → Add rule**
- **Branch name pattern**: `staging`
- **Require a pull request before merging**
  - [x] Require approvals (1 reviewer)
- **Require status checks to pass before merging**
  - [x] Status checks: `test`, `build-and-deploy`
- **Include administrators**
- **Allow force pushes**: ❌ Disabled
- **Allow deletions**: ❌ Disabled

### Develop Branch (`develop`) - Development
**Settings → Branches → Add rule**
- **Branch name pattern**: `develop`
- **Require status checks to pass before merging**
  - [x] Status checks: `test`
- **Include administrators**
- **Allow force pushes**: ❌ Disabled
- **Allow deletions**: ❌ Disabled

## Workflow

```
feature-branch → develop → staging → main
     ↓              ↓         ↓       ↓
   Local dev    DEV env   STAGING   PROD
   testing      testing   testing   env
```

## Status Checks

The CI/CD pipeline provides these status checks:
- `test`: Runs Flutter analyze and unit tests
- `build-and-deploy`: Builds and deploys to appropriate environment

## Environment Protection

GitHub Environments are automatically created and protected:
- **development**: develop branch deployments
- **staging**: staging branch deployments
- **production**: main branch deployments

Each environment requires the `FIREBASE_TOKEN` secret for deployment.