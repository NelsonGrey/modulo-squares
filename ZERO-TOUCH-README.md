# ZERO-TOUCH GitHub Actions Runner Management

This system provides fully automated, zero-maintenance GitHub Actions self-hosted runners using GitHub CLI authentication for token generation.

## 🎯 Overview

- **Zero Manual Intervention**: Tokens refresh automatically every hour
- **GitHub CLI Authentication**: Simple one-time setup, no expiring PATs
- **Multi-Repository Support**: Single authentication manages all repositories
- **Docker + macOS Runners**: Both containerized and native runners
- **Health Monitoring**: Automatic recovery and status reporting

## 🏗️ Architecture

```
GitHub CLI
├── One-time authentication (gh auth login)
├── Automatic token generation via API
└── Secure credential storage

Launch Agents (macOS)
├── Hourly token refresh
├── Health checks
└── Automatic recovery

Docker Containers
├── Token auto-injection
├── Health monitoring
└── Auto-restart on failure
```

## 🚀 Quick Setup

### 1. Authenticate GitHub CLI

Run the one-time authentication:

```bash
gh auth login
```

Choose your preferred authentication method (GitHub.com recommended).

### 2. Run Zero-Touch Setup

Execute the automated setup script:

```bash
cd /Users/marknelson/Circus/Repositories/modulo-squares
./token-refresh.sh setup
```

This will:
- Verify GitHub CLI authentication
- Test repository access
- Configure automated token refresh

### 3. Start Runners

```bash
# Start Docker runners
for repo in modulo-squares vehicle-vitals wishlist-wizard; do
  cd "/Users/marknelson/Circus/Repositories/${repo}-actions-runner"
  ./manage-docker-runner.sh start
done

# Start macOS runners
for repo in modulo-squares vehicle-vitals wishlist-wizard; do
  cd "/Users/marknelson/Circus/Repositories/${repo}-actions-runner/actions-runner"
  ./run.sh &
done
```

### 4. Verify Status

Check that runners appear online in GitHub:
- https://github.com/mnelson3/modulo-squares/settings/actions/runners
- https://github.com/nelsongrey/vehicle-vitals/settings/actions/runners
- https://github.com/nelsongrey/wishlist-wizard/settings/actions/runners

```bash
# Start Docker runners
for repo in modulo-squares vehicle-vitals wishlist-wizard; do
  cd "/Users/marknelson/Circus/Repositories/${repo}-actions-runner"
  ./manage-docker-runner.sh start
done

# Start macOS runners
for repo in modulo-squares vehicle-vitals wishlist-wizard; do
  cd "/Users/marknelson/Circus/Repositories/${repo}-actions-runner/actions-runner"
  ./run.sh &
done
```

### 3. Verify Status

Check that runners appear online in GitHub:
- https://github.com/nelsongrey/modulo-squares/settings/actions/runners
- https://github.com/nelsongrey/vehicle-vitals/settings/actions/runners
- https://github.com/nelsongrey/wishlist-wizard/settings/actions/runners

## 🔧 Troubleshooting

### GitHub CLI Authentication Issues

If authentication fails:

```bash
# Re-authenticate
gh auth login

# Check status
gh auth status

# Test API access
gh api user
```

### Repository Access Issues

Ensure you have admin access to repositories:

```bash
# Check your access
gh repo view mnelson3/modulo-squares
gh repo view nelsongrey/vehicle-vitals
gh repo view nelsongrey/wishlist-wizard
```

### Runner Offline Issues

If runners go offline:

```bash
# Force token refresh
./token-refresh.sh force_refresh

# Check container status
docker ps | grep runner

# Restart containers
docker-compose -f docker-compose.runner.yml restart
```

## 🔄 How It Works

### Token Flow

1. **GitHub CLI**: Uses stored authentication credentials
2. **API Calls**: Direct REST API calls to GitHub for token generation
3. **Auto-Refresh**: Process repeats hourly via launch agents

### Security

- **Stored Credentials**: GitHub CLI securely stores authentication
- **Short-Lived Tokens**: Runner tokens expire in 1 hour
- **Local Storage**: No sensitive data committed to repositories
- **Scoped Access**: App only has necessary permissions
- **No Secrets in Code**: All sensitive data in local files

## 🛠️ Maintenance

### Health Checks

```bash
# Check runner health
cd /Users/marknelson/Circus/Repositories/modulo-squares
./token-refresh.sh health_check
```

### Force Refresh

```bash
# Force token refresh
cd /Users/marknelson/Circus/Repositories/modulo-squares
./token-refresh.sh force_refresh
```

### Logs

Check logs at `/tmp/runner-token-refresh.log`

## 📁 File Structure

```
repository/
├── .env.runner                    # GitHub App configuration
├── .github-app-private-key.pem    # Private key (not committed)
├── token-refresh.sh              # Token management script
├── com.*.runner-token-refresh.plist  # Launch agent
└── docker-compose.runner.yml     # Docker runner config

actions-runner/
├── actions-runner/               # macOS runner binaries
├── docker-compose.yml            # Docker runner orchestration
└── manage-docker-runner.sh       # Docker runner control
```

## 🔒 Security Considerations

- Keep private keys secure and never commit them
- Regularly rotate GitHub App private keys
- Monitor GitHub App usage in settings
- Use organization-level apps for team access
- Consider IP allowlisting for additional security

## 🐛 Troubleshooting

### Runners Offline

1. Check token refresh logs: `tail -f /tmp/runner-token-refresh.log`
2. Verify GitHub App installation
3. Test token generation: `./token-refresh.sh force_refresh`
4. Check Docker/macOS runner processes

### Authentication Errors

1. Verify App ID and Installation ID in `.env.runner`
2. Check private key file exists and has correct permissions
3. Test JWT generation manually
4. Ensure GitHub App has correct permissions

### Permission Issues

1. Check GitHub App repository permissions
2. Verify app is installed on target repositories
3. Confirm user has admin access to repositories

## 📊 Monitoring

The system includes automatic monitoring:

- **Launch Agents**: macOS services run every hour
- **Health Checks**: Container and process monitoring
- **Log Rotation**: Automatic log management
- **Error Recovery**: Automatic restart on failures

## 🎉 Benefits

- ✅ **Zero Maintenance**: No manual token renewal
- ✅ **High Security**: Short-lived tokens, scoped access
- ✅ **Reliable**: Automatic health checks and recovery
- ✅ **Scalable**: Single app manages multiple repositories
- ✅ **Cost Effective**: No external services required

---

**Status**: 🟢 Production Ready

This ZERO-TOUCH system eliminates all manual runner management while maintaining enterprise-grade security and reliability.