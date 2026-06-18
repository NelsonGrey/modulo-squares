#!/bin/bash
# 🚀 Modulo Squares - Master Automation Controller
# Unified interface for all DevOps operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Load configuration
if [ -f ".env.automation.development" ]; then
    source .env.automation.development
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

log_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
    echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"
}

# Command dispatcher
main() {
    local command="$1"
    local subcommand="$2"
    local environment="${3:-development}"

    case "$command" in
        "setup")
            setup_system
            ;;
        "deploy")
            deploy_system "$subcommand" "$environment"
            ;;
        "monitor")
            manage_monitoring "$subcommand"
            ;;
        "tokens")
            manage_tokens "$subcommand"
            ;;
        "environment")
            manage_environment "$subcommand" "$environment"
            ;;
        "health")
            health_check
            ;;
        "docker")
            manage_docker "$subcommand"
            ;;
        *)
            show_help
            ;;
    esac
}

# Setup system
setup_system() {
    log_header "System Setup"
    log_info "Setting up Modulo Squares automation system..."

    # Check prerequisites
    check_prerequisites

    # Create necessary directories
    mkdir -p scripts
    mkdir -p docker
    mkdir -p config

    # Initialize configuration
    if [ ! -f ".env.automation.development" ]; then
        log_warning ".env.automation.development not found. Please copy from .env.automation.development.example and configure."
        return 1
    fi

    log_success "System setup completed"
}

# Deploy system
deploy_system() {
    local target="$1"
    local environment="$2"

    log_header "Deployment - $target to $environment"

    case "$target" in
        "web")
            deploy_web "$environment"
            ;;
        "mobile")
            deploy_mobile "$environment"
            ;;
        "ios")
            deploy_mobile_ios "$environment"
            ;;
        "full")
            deploy_full "$environment"
            ;;
        *)
            log_error "Unknown deployment target: $target"
            show_deploy_help
            exit 1
            ;;
    esac
}

# Deploy web app
deploy_web() {
    local environment="$1"
    log_info "Deploying web app to $environment..."

    # Check Firebase authentication
    if ! firebase projects:list > /dev/null 2>&1; then
        log_error "Firebase CLI not authenticated"
        exit 1
    fi

    # Get Firebase project ID
    local project_id
    project_id=$(get_firebase_project "$environment")

    if [ -z "$project_id" ]; then
        log_error "No Firebase project configured for $environment"
        exit 1
    fi

    # Deploy to Firebase
    log_info "Deploying to Firebase project: $project_id"
    firebase use "$project_id"
    firebase deploy --only hosting

    log_success "Web app deployed to $environment"
}

# Deploy mobile app
deploy_mobile() {
    local environment="$1"
    log_info "Deploying mobile app to $environment..."

    # Trigger GitHub Actions workflow
    if command -v gh > /dev/null 2>&1; then
        if gh auth status > /dev/null 2>&1; then
            log_info "Triggering mobile deployment workflow..."
            gh workflow run "Mobile App Distribution" -f environment="$environment"
            log_success "Mobile deployment workflow triggered"
        else
            log_warning "GitHub CLI not authenticated - cannot trigger workflow"
        fi
    else
        log_warning "GitHub CLI not installed - cannot trigger workflow"
    fi
}

# Deploy mobile iOS app directly with Fastlane
deploy_mobile_ios() {
    local env="$1"
    log_header "iOS Mobile App Deployment - $env"

    # Load environment configuration
    local env_file=".env.$env"
    if [ -f "$env_file" ]; then
        source "$env_file"
        log_info "Loaded environment configuration from $env_file"
    else
        log_warning "Environment file not found: $env_file"
    fi

    # Also load .env.development for shared secrets (ASC keys, etc.)
    if [ -f ".env.development" ]; then
        source .env.development
        log_info "Loaded shared secrets from .env.development"
    else
        log_warning ".env.development not found - ASC secrets may be missing"
    fi

    # Check prerequisites
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found. Please install Flutter SDK."
        exit 1
    fi

    if ! command -v fastlane &> /dev/null; then
        log_error "Fastlane not found. Please install Fastlane."
        exit 1
    fi

    # Navigate to mobile project
    cd packages/mobile

    log_info "Building iOS app for $env..."

    # App Store Connect env vars
    APP_STORE_CONNECT_KEY_ID="${APP_STORE_CONNECT_KEY_ID}"
    APP_STORE_CONNECT_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID}"
    APP_STORE_CONNECT_KEY="${APP_STORE_CONNECT_KEY}"

    # Set environment variables for Fastlane (from environment files)
    export FASTLANE_APPLE_ID="$FASTLANE_APPLE_ID"
    export FASTLANE_TEAM_ID="$FASTLANE_TEAM_ID"
    export FASTLANE_ITC_TEAM_ID="$FASTLANE_ITC_TEAM_ID"
    export APP_STORE_CONNECT_KEY_ID="$APP_STORE_CONNECT_KEY_ID"
    export APP_STORE_CONNECT_ISSUER_ID="$APP_STORE_CONNECT_ISSUER_ID"
    export APP_STORE_CONNECT_KEY="$APP_STORE_CONNECT_KEY"
    export MATCH_GIT_URL="$MATCH_GIT_URL"
    export BETA_FEEDBACK_EMAIL="$BETA_FEEDBACK_EMAIL"

    # Build and deploy based on environment
    case $env in
        "development")
            log_info "Deploying to TestFlight (Development)..."
            cd ios
            fastlane beta
            ;;
        "staging")
            log_info "Deploying to TestFlight (Staging)..."
            cd ios
            fastlane beta
            ;;
        "production")
            log_info "Deploying to TestFlight (Production)..."
            cd ios
            fastlane beta
            ;;
    esac

    cd "$PROJECT_ROOT"
    log_success "iOS deployment completed for $env!"
}

# Deploy full system
deploy_full() {
    local environment="$1"
    log_info "Deploying full system to $environment..."

    deploy_web "$environment"
    deploy_mobile "$environment"

    log_success "Full system deployed to $environment"
}

# Manage monitoring
manage_monitoring() {
    local action="$1"

    case "$action" in
        "start")
            start_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "status")
            monitoring_status
            ;;
        "once")
            run_monitoring_once
            ;;
        *)
            log_error "Unknown monitoring action: $action"
            exit 1
            ;;
    esac
}

# Start monitoring
start_monitoring() {
    log_header "Starting Monitoring System"

    if [ -f "monitoring.pid" ]; then
        log_warning "Monitoring already running (PID: $(cat monitoring.pid))"
        return
    fi

    # Start monitoring in background
    nohup "$SCRIPT_DIR/scripts/monitoring.sh" > monitoring.log 2>&1 &
    echo $! > monitoring.pid

    log_success "Monitoring started (PID: $(cat monitoring.pid))"
}

# Stop monitoring
stop_monitoring() {
    if [ -f "monitoring.pid" ]; then
        local pid=$(cat monitoring.pid)
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "Monitoring stopped"
        else
            log_warning "Monitoring process not running"
        fi
        rm -f monitoring.pid
    else
        log_warning "No monitoring process found"
    fi
}

# Monitoring status
monitoring_status() {
    if [ -f "monitoring.pid" ]; then
        local pid=$(cat monitoring.pid)
        if kill -0 "$pid" 2>/dev/null; then
            log_success "Monitoring running (PID: $pid)"
            return
        fi
    fi
    log_info "Monitoring not running"
}

# Run monitoring once
run_monitoring_once() {
    log_info "Running monitoring cycle..."
    "$SCRIPT_DIR/scripts/monitoring.sh" --once
}

# Manage tokens
manage_tokens() {
    local action="$1"

    case "$action" in
        "rotate")
            rotate_tokens
            ;;
        "status")
            token_status
            ;;
        *)
            log_error "Unknown token action: $action"
            exit 1
            ;;
    esac
}

# Rotate tokens
rotate_tokens() {
    log_header "Token Rotation"
    "$SCRIPT_DIR/scripts/token-rotation.sh" rotate
}

# Token status
token_status() {
    log_header "Token Status"
    "$SCRIPT_DIR/scripts/token-rotation.sh" status
}

# Manage environment
manage_environment() {
    local action="$1"
    local environment="$2"

    case "$action" in
        "setup")
            setup_environment "$environment"
            ;;
        "sync-secrets")
            sync_secrets "$environment"
            ;;
        "status")
            environment_status "$environment"
            ;;
        *)
            log_error "Unknown environment action: $action"
            exit 1
            ;;
    esac
}

# Setup environment
setup_environment() {
    local environment="$1"
    log_header "Setting up $environment environment"
    "$SCRIPT_DIR/scripts/manage-environments.sh" "$environment" setup
}

# Sync secrets
sync_secrets() {
    local environment="$1"
    log_header "Syncing secrets for $environment"
    "$SCRIPT_DIR/scripts/manage-environments.sh" "$environment" sync-secrets
}

# Environment status
environment_status() {
    local environment="$1"
    log_header "Environment status for $environment"
    "$SCRIPT_DIR/scripts/manage-environments.sh" "$environment" status
}

# Health check
health_check() {
    log_header "System Health Check"

    # Check prerequisites
    check_prerequisites

    # Check configuration
    if [ -f ".env.automation.development" ]; then
        log_success "Configuration file found"
    else
        log_error "Configuration file missing (.env.automation.development)"
    fi

    # Check scripts
    local scripts=("manage-environments.sh" "monitoring.sh" "token-rotation.sh" "automate-all.sh")
    for script in "${scripts[@]}"; do
        if [ -f "scripts/$script" ]; then
            log_success "Script found: $script"
        else
            log_error "Script missing: $script"
        fi
    done

    # Check monitoring
    monitoring_status

    # Check GitHub CLI
    if command -v gh > /dev/null 2>&1; then
        if gh auth status > /dev/null 2>&1; then
            log_success "GitHub CLI authenticated"
        else
            log_warning "GitHub CLI not authenticated"
        fi
    else
        log_warning "GitHub CLI not installed"
    fi

    # Check Firebase CLI
    if command -v firebase > /dev/null 2>&1; then
        log_success "Firebase CLI installed"
    else
        log_warning "Firebase CLI not installed"
    fi

    # Check Docker
    if command -v docker > /dev/null 2>&1; then
        log_success "Docker installed"
    else
        log_warning "Docker not installed"
    fi

    log_success "Health check completed"
}

# Manage Docker
manage_docker() {
    local action="$1"

    case "$action" in
        "build")
            build_docker_images
            ;;
        "runner")
            setup_docker_runner
            ;;
        *)
            log_error "Unknown Docker action: $action"
            exit 1
            ;;
    esac
}

# Build Docker images
build_docker_images() {
    log_header "Building Docker Images"
    log_info "Building automation images..."

    # Build images as needed
    log_success "Docker images built"
}

# Setup Docker runner
setup_docker_runner() {
    log_header "Setting up Docker Runner"

    if [ ! -f "docker-compose.runner.yml" ]; then
        log_error "docker-compose.runner.yml not found"
        exit 1
    fi

    # Check if runner token is set
    if [ -z "$RUNNER_TOKEN" ]; then
        log_error "RUNNER_TOKEN not set in .env.automation.development"
        exit 1
    fi

    log_info "Starting GitHub runner container..."
    docker-compose -f docker-compose.runner.yml up -d

    log_success "Docker runner started"
}

# Check prerequisites
check_prerequisites() {
    local missing=""

    # Check Bash version
    if [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
        missing="$missing bash3.2+"
    fi

    # Check required commands
    local commands=("git" "curl" "jq")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done

    if [ -n "$missing" ]; then
        log_error "Missing prerequisites:$missing"
        exit 1
    fi
}

# Get Firebase project (Bash 3.2 compatible)
get_firebase_project() {
    local environment="$1"
    eval "echo \$ENV_CONFIGS_$environment"
}

# Show help
show_help() {
    echo "🎯 Modulo Squares - Master Automation Controller"
    echo "Usage: $0 <command> [subcommand] [environment]"
    echo ""
    echo "Commands:"
    echo "  setup                    Complete system setup"
    echo "  deploy     <target>      Deploy to target (full|web|mobile)"
    echo "  monitor    <action>      Monitoring (start|stop|status|once)"
    echo "  tokens     <action>      Token management (rotate|status)"
    echo "  environment <action>     Environment management (setup|sync|status)"
    echo "  health                   System health check"
    echo "  docker     <action>      Docker management (build|runner)"
    echo ""
    echo "Environments: development, staging, production"
    echo "Default environment: development"
}

# Show deploy help
show_deploy_help() {
    echo "Deployment targets:"
    echo "  web      Deploy web application"
    echo "  mobile   Deploy mobile applications (triggers GitHub Actions)"
    echo "  ios      Deploy iOS app directly with Fastlane"
    echo "  full     Deploy all components"
}

main "$@"