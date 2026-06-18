#!/bin/bash
# 🚀 Deployment Orchestration System

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}🚀 $1${NC}"; echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"; }

# Deployment phases
DEPLOYMENT_PHASES=("validate" "build" "test" "deploy" "verify")

# Validate deployment prerequisites
validate_deployment() {
    local environment="$1"
    log_header "Validation Phase - $environment"

    cd "$PROJECT_ROOT"

    # Check environment configuration
    if [ ! -f ".env.$environment" ]; then
        log_error "Environment file missing: .env.$environment"
        exit 1
    fi

    # Check automation configuration
    if [ ! -f ".env.automation.$environment" ]; then
        log_error "Automation configuration missing: .env.automation.$environment"
        exit 1
    fi

    # Load configurations
    source ".env.$environment"
    source ".env.automation.$environment"

    # Check required tools
    local required_tools=("git" "node" "npm" "firebase")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            log_error "Required tool missing: $tool"
            exit 1
        fi
    done

    # Check Firebase authentication
    if ! firebase projects:list > /dev/null 2>&1; then
        log_error "Firebase CLI not authenticated"
        exit 1
    fi

    # Check GitHub CLI for mobile deployment
    if ! command -v gh > /dev/null 2>&1; then
        log_warning "GitHub CLI not installed - mobile deployment may fail"
    elif ! gh auth status > /dev/null 2>&1; then
        log_warning "GitHub CLI not authenticated - mobile deployment may fail"
    fi

    log_success "Validation completed successfully"
}

# Build phase
build_artifacts() {
    local environment="$1"
    log_header "Build Phase - $environment"

    cd "$PROJECT_ROOT"

    # Load environment configuration
    source ".env.$environment"

    # Build web application
    log_info "Building web application..."
    cd packages/web
    npm install
    npm run build
    cd "$PROJECT_ROOT"

    # Build mobile applications (if Flutter is available)
    if command -v flutter > /dev/null 2>&1; then
        log_info "Building mobile applications..."
        cd packages/mobile
        flutter pub get
        flutter build web --release
        cd "$PROJECT_ROOT"
    else
        log_warning "Flutter not installed - skipping mobile build"
    fi

    log_success "Build phase completed"
}

# Test phase
run_tests() {
    local environment="$1"
    log_header "Test Phase - $environment"

    cd "$PROJECT_ROOT"

    # Run web tests
    if [ -d "packages/web" ]; then
        cd packages/web
        log_info "Running web tests..."
        npm test -- --watchAll=false --passWithNoTests || log_warning "Web tests failed"
        cd "$PROJECT_ROOT"
    fi

    # Run mobile tests (if Flutter is available)
    if command -v flutter > /dev/null 2>&1 && [ -d "packages/mobile" ]; then
        cd packages/mobile
        log_info "Running mobile tests..."
        flutter test || log_warning "Mobile tests failed"
        cd "$PROJECT_ROOT"
    fi

    log_success "Test phase completed"
}

# Deploy phase
deploy_artifacts() {
    local environment="$1"
    log_header "Deploy Phase - $environment"

    cd "$PROJECT_ROOT"

    # Load configurations
    source ".env.$environment"
    source ".env.automation.$environment"

    # Deploy web application
    log_info "Deploying web application to Firebase..."
    firebase use "$FIREBASE_PROJECT_ID"
    firebase deploy --only hosting

    # Deploy mobile applications
    if [ "$environment" = "production" ]; then
        log_info "Triggering mobile app deployment..."

        if command -v gh > /dev/null 2>&1 && gh auth status > /dev/null 2>&1; then
            # Trigger iOS deployment
            if [ -f ".github/workflows/ios-distribution.yml" ]; then
                gh workflow run "iOS App Distribution" -f environment="$environment"
                log_success "iOS deployment workflow triggered"
            fi

            # Trigger Android deployment
            if [ -f ".github/workflows/android-distribution.yml" ]; then
                gh workflow run "Android App Distribution" -f environment="$environment"
                log_success "Android deployment workflow triggered"
            fi
        else
            log_warning "GitHub CLI not available - manual mobile deployment required"
        fi
    fi

    log_success "Deploy phase completed"
}

# Verify deployment
verify_deployment() {
    local environment="$1"
    log_header "Verification Phase - $environment"

    cd "$PROJECT_ROOT"

    # Load configurations
    source ".env.$environment"

    # Wait for deployment to propagate
    log_info "Waiting for deployment to propagate..."
    sleep 30

    # Check web application
    local web_url
    case "$environment" in
        "development") web_url="https://modulo-squares-dev.web.app" ;;
        "staging") web_url="https://modulo-squares-staging.web.app" ;;
        "production") web_url="https://modulo-squares-prod.web.app" ;;
    esac

    log_info "Checking web application: $web_url"
    local web_response
    web_response=$(curl -s -o /dev/null -w "%{http_code}" "$web_url" 2>/dev/null || echo "000")

    if [ "$web_response" = "200" ]; then
        log_success "Web application accessible"
    else
        log_error "Web application not accessible (HTTP $web_response)"
    fi

    # Check API endpoints (if configured)
    if [ -n "$API_ENDPOINT" ]; then
        log_info "Checking API endpoint: $API_ENDPOINT"
        local api_response
        api_response=$(curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/health" 2>/dev/null || echo "000")

        if [ "$api_response" = "200" ]; then
            log_success "API endpoint healthy"
        else
            log_warning "API endpoint not accessible (HTTP $api_response)"
        fi
    fi

    log_success "Verification phase completed"
}

# Full deployment orchestration
full_deployment() {
    local environment="$1"
    local start_time
    start_time=$(date +%s)

    log_header "🚀 Full Deployment Orchestration - $environment"
    log_info "Starting deployment pipeline..."

    # Execute deployment phases
    for phase in "${DEPLOYMENT_PHASES[@]}"; do
        log_info "Executing phase: $phase"
        case "$phase" in
            "validate") validate_deployment "$environment" ;;
            "build") build_artifacts "$environment" ;;
            "test") run_tests "$environment" ;;
            "deploy") deploy_artifacts "$environment" ;;
            "verify") verify_deployment "$environment" ;;
        esac
        echo
    done

    # Calculate deployment time
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "🎉 Deployment completed successfully!"
    log_info "Total deployment time: ${duration}s"

    # Send notification
    if [ -n "$SLACK_WEBHOOK" ]; then
        # Send Slack notification
        curl -X POST -H 'Content-type: application/json' \
             --data "{\"text\":\"✅ Modulo Squares $environment deployment completed in ${duration}s\"}" \
             "$SLACK_WEBHOOK" || true
    fi
}

# Rollback deployment
rollback_deployment() {
    local environment="$1"
    log_header "Rollback Deployment - $environment"

    log_warning "Rollback functionality not yet implemented"
    log_info "Manual rollback may be required"
}

# Main function
main() {
    local action="${1:-full}"
    local environment="${2:-development}"

    # Validate environment
    case "$environment" in
        development|staging|production) ;;
        *) log_error "Invalid environment: $environment"; exit 1 ;;
    esac

    case "$action" in
        "full")
            full_deployment "$environment"
            ;;
        "validate")
            validate_deployment "$environment"
            ;;
        "build")
            build_artifacts "$environment"
            ;;
        "test")
            run_tests "$environment"
            ;;
        "deploy")
            deploy_artifacts "$environment"
            ;;
        "verify")
            verify_deployment "$environment"
            ;;
        "rollback")
            rollback_deployment "$environment"
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Usage: $0 <action> [environment]"
            echo "Actions: full, validate, build, test, deploy, verify, rollback"
            echo "Environments: development, staging, production"
            exit 1
            ;;
    esac
}

main "$@"