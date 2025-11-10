# CI/CD Setup for Modulo Squares

This document describes the current CI/CD infrastructure setup for the Modulo Squares Flutter project.

## 🎯 Current Setup

The project includes a complete self-hosted CI/CD infrastructure with:

- **Self-hosted GitHub Actions runners** (macOS for iOS builds)
- **Automated workflows** for CI/CD, testing, and app distribution
- **Cost monitoring** and infrastructure management
- **Documentation** and maintenance guides

**Cost Savings**: ~90% reduction compared to GitHub-hosted runners

## 🚀 Current Infrastructure

### Workflows (`.github/workflows/`)
- `ci-cd-pipeline.yml` - Main CI/CD pipeline (currently disabled)
- `ios-distribution.yml` - iOS app distribution to Firebase App Distribution
- `android-distribution.yml` - Android app distribution to Firebase App Distribution
- `web-deployment.yml` - Web app deployment to Firebase Hosting

### Scripts (`scripts/`)
- `manage-macos-runner.sh` - macOS runner lifecycle management
- `setup-macos-runner.sh` - macOS runner initial setup
- `monitor-github-actions-costs.sh` - Cost analysis and monitoring
- `switch-mobile-configs.sh` - Environment configuration switching

### Runner Configuration
- **macOS Runner**: Self-hosted on macOS with Flutter, Xcode, and iOS Simulator
- **Labels**: `self-hosted`, `macos-latest`, `arm64`
- **Auto-restart**: Configured as launchd service

## 🛠️ Maintenance & Operation

### Checking Runner Status
```bash
# View runner status
./scripts/manage-macos-runner.sh status

# View runner logs
./scripts/manage-macos-runner.sh logs
```

### Monitoring Costs
```bash
# Analyze GitHub Actions costs
./scripts/monitor-github-actions-costs.sh
```

### Managing the Runner
```bash
# Stop the runner
./scripts/manage-macos-runner.sh stop

# Start the runner
./scripts/manage-macos-runner.sh start

# Restart the runner
./scripts/manage-macos-runner.sh stop && ./scripts/manage-macos-runner.sh start

# Update runner software
./scripts/manage-macos-runner.sh update
```

## 📋 Workflow Configuration

### iOS Distribution
- **Trigger**: Push to `main`, `develop`, `staging` branches
- **Environment**: Matches branch (`DEVELOPMENT`, `STAGING`, `PRODUCTION`)
- **Build**: Debug build for simulator, distributed to Firebase App Distribution
- **Requirements**: iOS Simulator, Flutter, Xcode 26.1+

### Android Distribution
- **Trigger**: Push to `main`, `develop`, `staging` branches
- **Environment**: Matches branch (`DEVELOPMENT`, `STAGING`, `PRODUCTION`)
- **Build**: Debug APK distributed to Firebase App Distribution
- **Requirements**: Android SDK, Flutter

### Web Deployment
- **Trigger**: Push to `main` branch
- **Build**: Flutter web build deployed to Firebase Hosting
- **Requirements**: Flutter, Firebase CLI

## 🔧 Troubleshooting

### Runner Issues
```bash
# Check if runner service is running
./scripts/manage-macos-runner.sh status

# View detailed logs
./scripts/manage-macos-runner.sh logs

# Restart if needed
./scripts/manage-macos-runner.sh stop
./scripts/manage-macos-runner.sh start
```

### Workflow Failures
- **iOS Build Issues**: Ensure Xcode 26.1+ and iOS Simulator are available
- **Android Build Issues**: Check Android SDK installation
- **Permission Issues**: Verify runner has access to required directories
- **Network Issues**: Check firewall and GitHub connectivity

### Common Solutions
1. **Runner not responding**: Restart the runner service
2. **iOS simulator issues**: Boot simulator manually or restart Xcode
3. **Permission denied**: Check file permissions on Flutter/Android SDK paths
4. **Build cache issues**: Clean Flutter build cache (`flutter clean`)

## � Cost Monitoring

### Current Costs (Estimated)
- **Self-hosted macOS**: ~$5-10/month (hardware + electricity)
- **GitHub Actions**: Minimal (only for coordination)
- **Total Savings**: ~90% vs GitHub-hosted runners

### Monitoring Commands
```bash
# View cost analysis
./scripts/monitor-github-actions-costs.sh

# Check runner utilization
./scripts/manage-macos-runner.sh status
```

## 🔄 Updates & Maintenance

### Regular Maintenance
- **Weekly**: Check runner status and logs
- **Monthly**: Review cost reports and utilization
- **Quarterly**: Update runner software and dependencies

### Updating Runner Software
```bash
# Update GitHub Actions runner
./scripts/manage-macos-runner.sh update

# Update Flutter and dependencies
flutter upgrade
```

## 📚 Related Documentation

- `docs/COST_EFFECTIVE_CICD.md` - Cost analysis and benefits
- `docs/SELF_HOSTED_RUNNERS.md` - Runner setup details
- `docs/SELF_HOSTED_RUNNER_SETUP.md` - Detailed setup instructions
- `README.md` - Project overview and quick start

## 🎯 Best Practices

1. **Monitor runner health** regularly
2. **Keep dependencies updated** (Flutter, Xcode, Android SDK)
3. **Review costs monthly** to track savings
4. **Test workflows** after major changes
5. **Document issues** and solutions for future reference

---

**CI/CD infrastructure active and saving ~90% on build costs!** ✅