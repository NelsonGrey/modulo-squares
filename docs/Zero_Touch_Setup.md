# ZERO-TOUCH CI/CD Setup Guide

This guide covers the complete ZERO-TOUCH DevOps pipeline for the Modulo Squares project, including automated certificate management, token refresh, and self-hosted runner maintenance.

## 🚀 Overview

The ZERO-TOUCH pipeline ensures that CI/CD operations run without manual intervention:
- **Certificate Management**: Automatic iOS certificate and provisioning profile creation
- **Token Refresh**: Automated GitHub runner token renewal
- **Runner Health**: Self-healing Docker containers with monitoring
- **Build Automation**: Fully automated iOS distribution builds

## 📋 Prerequisites

1. **GitHub Personal Access Token (PAT)**:
   - Go to https://github.com/settings/tokens
   - Create a new token with `repo` scope
   - Add it to `.env.runner`: `GITHUB_PAT=your_token_here`

2. **Docker Environment**:
   - Docker Desktop installed and running
   - Sufficient disk space for containers

3. **macOS Development**:
   - Xcode installed with command line tools
   - Apple Developer Program membership
   - Fastlane match repository access

## 🛠️ Setup Instructions

### 1. Configure GitHub PAT

```bash
# Edit the .env.runner file
nano .env.runner

# Replace YOUR_GITHUB_PAT_HERE with your actual PAT
GITHUB_PAT=REDACTED_GITHUB_TOKEN
```

### 2. Install Dependencies

```bash
# Install Node.js dependencies for monitoring
npm install

# Install Flutter and Fastlane (if not already done)
# Follow the existing setup guides in docs/
```

### 3. Start the Runner Infrastructure

```bash
# Start Docker containers (runner + monitoring)
docker-compose -f docker-compose.runner.yml up -d

# Verify containers are running
docker-compose -f docker-compose.runner.yml ps
```

### 4. Verify Monitoring Dashboard

- Open http://localhost:8082 in your browser
- Check runner status and token validity
- Monitor system metrics

### 5. Test Token Refresh (Optional)

```bash
# Manual token refresh test
./token-refresh.sh force_refresh

# Check logs
tail -f /tmp/runner-token-refresh.log
```

## 🔄 Automated Operations

### Token Refresh
- **Frequency**: Every hour (configurable via `TOKEN_CHECK_INTERVAL`)
- **Trigger**: launchd job on macOS
- **Process**:
  1. Checks runner health
  2. Calls GitHub API for new token
  3. Updates `.env.runner`
  4. Restarts Docker containers
  5. Verifies runner comes back online

### Certificate Management
- **Tool**: Fastlane Match
- **Storage**: Encrypted Git repository
- **Process**: Automatic profile generation during iOS builds

### Health Monitoring
- **Dashboard**: http://localhost:8082
- **Endpoints**:
  - `/health` - Runner health status
  - `/token-status` - Token validity and expiration
  - `/logs` - Token refresh logs

## 📊 Monitoring & Troubleshooting

### Common Issues

1. **Runner Offline**:
   ```bash
   # Check container status
   docker-compose -f docker-compose.runner.yml ps

   # View runner logs
   docker-compose -f docker-compose.runner.yml logs github-runner

   # Force token refresh
   ./token-refresh.sh force_refresh
   ```

2. **Token Refresh Failures**:
   ```bash
   # Check GitHub PAT validity
   curl -H "Authorization: token YOUR_PAT" https://api.github.com/user

   # Verify API permissions
   # PAT must have 'repo' scope
   ```

3. **Certificate Issues**:
   ```bash
   # Check Fastlane match status
   cd packages/mobile
   fastlane match development --readonly
   ```

### Log Files
- **Token Refresh**: `/tmp/runner-token-refresh.log`
- **Runner Logs**: `docker-compose -f docker-compose.runner.yml logs`
- **Build Logs**: GitHub Actions workflow runs

## 🔧 Configuration Files

### .env.runner
```dotenv
RUNNER_TOKEN=AIQEPB3LJ6IZQIJ5NPHEJULJE5ACC
GITHUB_PAT=your_github_pat
TOKEN_CHECK_INTERVAL=3600
TOKEN_REFRESH_BUFFER=86400
TOKEN_LOG_FILE=/tmp/runner-token-refresh.log
```

### docker-compose.runner.yml
- Defines runner and monitoring containers
- Mounts Docker socket for container builds
- Configures networking and volumes

### token-refresh.sh
- Bash script for automated token management
- Uses GitHub API to generate new tokens
- Handles container restart and health verification

## 🚦 Status Indicators

### Dashboard Status
- 🟢 **Healthy**: Runner online, token valid
- 🟡 **Warning**: Token expiring soon
- 🔴 **Critical**: Runner offline or token expired

### Token Status
- ✅ **Valid**: Token active and not expiring soon
- ❌ **Invalid**: Token expired or invalid
- ❓ **Unknown**: Unable to determine status

## 🔄 Maintenance Tasks

### Weekly
- Review monitoring dashboard
- Check token refresh logs for errors
- Verify GitHub PAT is still valid

### Monthly
- Update Docker images: `docker-compose pull`
- Review certificate expiration dates
- Audit runner usage and performance

### Emergency
- **Runner Down**: Check Docker status, restart containers
- **Token Expired**: Run `./token-refresh.sh force_refresh`
- **Build Failures**: Check Fastlane match repository access

## 📞 Support

For issues with ZERO-TOUCH setup:
1. Check the monitoring dashboard
2. Review logs in `/tmp/runner-token-refresh.log`
3. Verify GitHub PAT permissions
4. Check Docker container status

The system is designed to be self-healing, but manual intervention may be required for configuration changes or external service issues.