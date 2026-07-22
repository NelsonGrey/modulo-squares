# Docker Hub Authentication Setup

> **Tooling reference (reviewed 2026-07-20):** Docker runner scripts remain in the repository, but the active application pipeline does not build or publish application Docker images.

This guide explains how to configure Docker Hub authentication using Personal Access Tokens (PATs) instead of stored credentials, which avoids macOS keychain issues.

## 🔑 Create Docker Hub Personal Access Token

1. **Go to Docker Hub**: https://hub.docker.com/settings/security
2. **Click "New Access Token"**
3. **Configure Token**:
   - **Name**: `modulo-squares-ci`
   - **Description**: `CI/CD token for Modulo Squares project`
   - **Permissions**: Read, Write, Delete
4. **Copy the token** (save it securely - you won't see it again!)

## 🔐 Add Secrets to GitHub Repository

Add the following secrets to your GitHub repository:

### Required Secrets:
- `DOCKERHUB_USERNAME`: Your Docker Hub username (e.g., `mnelson3`)
- `DOCKERHUB_TOKEN`: The Personal Access Token you created above

### Add Secrets:
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add both secrets listed above

## 🚀 How It Works

The CI/CD pipeline now uses Docker Hub authentication via PAT:

```yaml
- name: 🔐 Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

### Benefits:
- ✅ **No keychain issues**: PATs bypass macOS credential storage
- ✅ **Secure**: Tokens can be scoped and revoked individually
- ✅ **CI/CD friendly**: Works perfectly in automated environments
- ✅ **No manual intervention**: Authentication happens automatically

## 🐳 Docker Images

The pipeline builds and pushes the following images:

- `mnelson3/modulo-squares-web:latest` - Web application
- `mnelson3/modulo-squares-api:latest` - Firebase Functions API

Images are tagged with both `latest` and the commit SHA for traceability.

## 🔄 Deployment

The deployment process:
1. Builds Docker images from source
2. Pushes images to Docker Hub
3. Deploys containers to production/staging

This approach provides:
- **Consistency**: Same environment from dev to production
- **Scalability**: Easy to scale containerized applications
- **Reliability**: No dependency on local build environments

## 🛠️ Local Development

For local development, you can still use Docker normally:

```bash
# Login with your PAT
docker login --username mnelson3 --password <your_pat>

# Or use environment variables
export DOCKER_USERNAME=mnelson3
export DOCKER_PASSWORD=<your_pat>
docker login
```

## 🔒 Security Notes

- **Never commit PATs** to version control
- **Use minimal permissions** for CI/CD tokens
- **Rotate tokens regularly** for security
- **Monitor token usage** in Docker Hub security settings

## 🐛 Troubleshooting

### Authentication Issues:
```bash
# Test login manually
docker login --username mnelson3 --password <your_pat>

# Check if secrets are set
gh secret list  # Requires GitHub CLI
```

### Build Issues:
```bash
# Check Docker Hub repository exists
# Ensure your username matches the image tags in workflows
```

### Permission Issues:
```bash
# Verify PAT has correct permissions
# Check Docker Hub organization/team settings
```
