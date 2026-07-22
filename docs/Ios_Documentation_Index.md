# iOS Development Documentation Index

> **Reference index (reviewed 2026-07-20):** Use [Go-Live Runbook](GO_LIVE_RUNBOOK.md) for current launch state and [CI/CD Setup](Ci_Cd_Setup.md) for the active workflow.

> **Complete Guide Collection**: All documentation for setting up iOS projects with certificates, CI/CD, and automation.

## 📚 Documentation Overview

This collection provides everything needed to set up iOS projects with professional certificate management, CI/CD automation, and deployment pipelines.

## 📖 Available Guides

### 1. iOS Certificate Setup Guide
**File**: [`Ios_Certificate_Setup.md`](./Ios_Certificate_Setup.md)
**Purpose**: Complete step-by-step guide for setting up iOS certificate repositories
**Use When**: Starting a new iOS project, setting up certificates for the first time
**Includes**:
- Certificate repository creation
- Fastlane Match configuration
- App Store Connect API setup
- Environment variable configuration
- Troubleshooting common issues

### 2. iOS Certificate Quick Reference
**File**: [`Ios_Certificate_Quick_Reference.md`](./Ios_Certificate_Quick_Reference.md)
**Purpose**: Fast setup commands and essential configurations
**Use When**: Need a quick cheatsheet, setting up multiple projects
**Includes**:
- Copy-paste commands
- Environment variable templates
- GitHub Secrets checklist
- Troubleshooting quick fixes

### 3. iOS CI/CD Integration Guide
**File**: [`Ios_Cicd_Integration_Guide.md`](./Ios_Cicd_Integration_Guide.md)
**Purpose**: Complete CI/CD automation for iOS projects
**Use When**: Setting up automated builds, deployments, and testing
**Includes**:
- GitHub Actions templates
- GitLab CI configuration
- Jenkins Pipeline setup
- Self-hosted runner configuration
- Security best practices
- Performance optimization

### 4. iOS Project Template
**File**: [`Ios_Cicd_Integration_Guide.md`](./Ios_Cicd_Integration_Guide.md)
**Purpose**: Complete project starter with all configurations
**Use When**: Creating a new iOS project from scratch
**Includes**:
- Project structure template
- Setup automation script
- Fastlane configuration files
- GitHub Actions workflows
- Documentation templates

### 5. iOS Runner Readiness Check
**File**: [`../scripts/check-ios-runner-readiness.sh`](../scripts/check-ios-runner-readiness.sh)
**Purpose**: Fast local validation that a macOS self-hosted runner is ready for iOS CI jobs
**Use When**: Before running manual iOS validation or diagnosing runner failures
**Includes**:
- Xcode command/toolchain checks
- Xcode license/first-launch readiness check
- Optional CocoaPods/Flutter presence checks
- Suggested remediation commands on failure

## 🚀 Quick Start for New Projects

### Option 1: Use the Template (Recommended)
```bash
# 1. Copy the template files to your new project
cp docs/Ios_Cicd_Integration_Guide.md your-new-project/
cp docs/Ios_Certificate_Setup.md your-new-project/docs/
cp docs/Ios_Cicd_Integration_Guide.md your-new-project/docs/

# 2. Follow the setup script in the template
cd your-new-project
chmod +x scripts/setup-ios-project.sh
./scripts/setup-ios-project.sh
```

### Option 2: Manual Setup
```bash
# 1. Create certificate repository
# Follow: Ios_Certificate_Setup.md

# 2. Setup Fastlane
# Follow: Ios_Certificate_Quick_Reference.md

# 3. Configure CI/CD
# Follow: Ios_Cicd_Integration_Guide.md
```

## 📋 Checklist for New Projects

### Pre-Setup Requirements
- [ ] Apple Developer Program membership ($99/year)
- [ ] App Store Connect access (Admin role)
- [ ] GitHub account with private repository access
- [ ] macOS development environment

### Certificate Repository Setup
- [ ] Create private GitHub repository (`{project-name}-certificates`)
- [ ] Generate GitHub Personal Access Token
- [ ] Setup Fastlane Match configuration
- [ ] Generate development and distribution certificates

### Project Configuration
- [ ] Configure Fastlane Appfile and Fastfile
- [ ] Setup environment variables
- [ ] Configure CI/CD secrets
- [ ] Test local builds

### CI/CD Pipeline
- [ ] Setup GitHub Actions (or preferred CI platform)
- [ ] Configure self-hosted runners (optional, for cost savings)
- [ ] Test automated builds and deployments
- [ ] Setup notifications and monitoring

## 🔧 Key Components Explained

### Certificate Management
- **Separate Repository**: `{project-name}-certificates` for security
- **Fastlane Match**: Automated certificate and profile management
- **Git Storage**: Version control for certificates
- **Encrypted**: All sensitive data encrypted

### CI/CD Automation
- **Multi-Platform**: GitHub Actions, GitLab CI, Jenkins support
- **Cost Optimization**: Self-hosted runners save ~90% on costs
- **Security**: Secrets management and access controls
- **Monitoring**: Build status, performance metrics, alerts

### Deployment Pipeline
- **TestFlight**: Automated beta distribution
- **App Store**: Production releases
- **Multi-Environment**: Development, staging, production
- **Rollback**: Version control and emergency procedures

## 🎯 Use Cases

### For Different Team Sizes

**Solo Developer**:
- Use Quick Reference guide
- GitHub Actions with hosted runners
- Manual certificate management

**Small Team (2-10 developers)**:
- Use Setup Guide + CI/CD Integration
- Self-hosted runners for cost savings
- Automated certificate management

**Enterprise Team (10+ developers)**:
- Use Project Template + all guides
- Advanced CI/CD with GitLab/Jenkins
- Comprehensive monitoring and security

### For Different Project Types

**Flutter iOS App**:
- Follow all guides (Flutter-specific configurations included)
- Use Flutter build commands in Fastlane

**Native iOS App**:
- Adapt Fastlane commands for Xcode projects
- Use different build schemes and configurations

**Cross-Platform App**:
- Combine with Android setup guides
- Shared certificate management strategy

## 📊 Success Metrics

Track these to ensure successful implementation:

- **Setup Time**: < 2 hours for certificate + CI/CD setup
- **Build Success Rate**: > 95% for automated builds
- **Deployment Frequency**: Multiple releases per week
- **Certificate Validity**: > 30 days remaining
- **Cost Savings**: 80-90% with self-hosted runners

## 🔄 Maintenance & Updates

### Regular Tasks
- **Monthly**: Review certificate expiration
- **Weekly**: Check build pipeline status
- **Daily**: Monitor for failed builds

### Updates Needed
- Fastlane version updates (currently 2.228.0)
- macOS runner updates
- Security policy updates
- CI/CD platform changes

## 📞 Support & Resources

### Getting Help
1. Check troubleshooting sections in each guide
2. Review Fastlane documentation: https://docs.fastlane.tools
3. Apple Developer Forums: https://developer.apple.com/forums
4. GitHub Issues in this repository

### Related Documentation
- [macOS Runner Setup Guide](./Macos_Runner_Setup.md)
- [CI/CD Pipeline Guide](./Ci_Cd_Setup.md)
- [Fastlane Documentation](https://docs.fastlane.tools)
- [App Store Connect API](https://developer.apple.com/support/app-store-connect-api/)

---

## 🎉 You're Ready!

With these guides, you can:
- ✅ Setup secure iOS certificate management
- ✅ Configure automated CI/CD pipelines
- ✅ Deploy to TestFlight and App Store automatically
- ✅ Scale to multiple iOS projects
- ✅ Save costs with optimized infrastructure

**Start with the [iOS Certificate Setup](./Ios_Certificate_Setup.md)** for your first project!</content>
<parameter name="filePath">/Users/marknelson/Circus/Repositories/wishlist-wizard/docs/IOS_DOCUMENTATION_INDEX.md
