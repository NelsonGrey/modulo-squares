#!/bin/bash
# 🔄 Token Rotation & Credential Management System

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${ENVIRONMENT:-development}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}🔄 $1${NC}"; echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"; }

# Token types to manage
TOKEN_TYPES=("github" "firebase" "docker" "npm")

# GitHub token rotation
rotate_github_token() {
    log_header "GitHub Token Rotation"

    if ! command -v gh > /dev/null 2>&1; then
        log_error "GitHub CLI not installed"
        return 1
    fi

    if ! gh auth status > /dev/null 2>&1; then
        log_warning "GitHub CLI not authenticated - cannot rotate token"
        return 1
    fi

    log_info "Creating new GitHub personal access token..."
    log_warning "Manual intervention required: Create new PAT at https://github.com/settings/tokens"
    log_info "Required scopes: repo, workflow, admin:repo_hook, delete_repo"
    log_info "Update GITHUB_TOKEN in .env.automation.$ENVIRONMENT and repository secrets"

    # In a real implementation, you might use GitHub Apps or service accounts
    # For now, this is a manual process
}

# Firebase token rotation
rotate_firebase_token() {
    log_header "Firebase Service Account Rotation"

    if ! command -v firebase > /dev/null 2>&1; then
        log_error "Firebase CLI not installed"
        return 1
    fi

    log_info "Checking Firebase authentication..."
    if ! firebase projects:list > /dev/null 2>&1; then
        log_error "Firebase CLI not authenticated"
        return 1
    fi

    log_info "To rotate Firebase service account:"
    log_info "1. Go to Google Cloud Console → IAM & Admin → Service Accounts"
    log_info "2. Create new key for your Firebase service account"
    log_info "3. Download new JSON key"
    log_info "4. Update FIREBASE_SERVICE_ACCOUNT_KEY in .env.automation.$ENVIRONMENT"
    log_info "5. Update repository secrets"
}

# Docker registry token rotation
rotate_docker_token() {
    log_header "Docker Registry Token Rotation"

    if ! command -v docker > /dev/null 2>&1; then
        log_warning "Docker not installed - skipping"
        return 0
    fi

    log_info "To rotate Docker registry credentials:"
    log_info "1. Update DOCKER_USERNAME and DOCKER_PASSWORD in .env.automation.$ENVIRONMENT"
    log_info "2. Run: docker login your-registry.com"
    log_info "3. Test: docker pull your-registry.com/test-image"
}

# NPM token rotation
rotate_npm_token() {
    log_header "NPM Token Rotation"

    if ! command -v npm > /dev/null 2>&1; then
        log_warning "NPM not installed - skipping"
        return 0
    fi

    log_info "To rotate NPM token:"
    log_info "1. Go to npmjs.com → Access Tokens"
    log_info "2. Generate new automation token"
    log_info "3. Update NPM_TOKEN in .env.automation.$ENVIRONMENT"
    log_info "4. Run: npm config set //registry.npmjs.org/:_authToken YOUR_NEW_TOKEN"
}

# Rotate all tokens
rotate_all_tokens() {
    log_header "Rotating All Tokens"

    for token_type in "${TOKEN_TYPES[@]}"; do
        log_info "Rotating $token_type tokens..."
        case "$token_type" in
            "github") rotate_github_token ;;
            "firebase") rotate_firebase_token ;;
            "docker") rotate_docker_token ;;
            "npm") rotate_npm_token ;;
        esac
        echo
    done

    log_success "Token rotation process completed"
    log_warning "Remember to update .env.automation.$ENVIRONMENT and repository secrets with new tokens"
}

# Check token status
check_token_status() {
    log_header "Token Status Check"

    cd "$PROJECT_ROOT"

    # Load configuration
    ENVIRONMENT="${ENVIRONMENT:-development}"
    if [ -f ".env.automation.$ENVIRONMENT" ]; then
        source ".env.automation.$ENVIRONMENT"
    fi

    # Check GitHub token
    if [ -n "$GITHUB_TOKEN" ]; then
        log_success "GitHub token configured"
        if command -v gh > /dev/null 2>&1; then
            if gh auth status > /dev/null 2>&1; then
                log_success "GitHub CLI authenticated"
            else
                log_warning "GitHub CLI not authenticated"
            fi
        fi
    else
        log_warning "GitHub token not configured"
    fi

    # Check Firebase service account
    if [ -n "$FIREBASE_SERVICE_ACCOUNT_KEY" ]; then
        log_success "Firebase service account configured"
        if command -v firebase > /dev/null 2>&1; then
            if firebase projects:list > /dev/null 2>&1; then
                log_success "Firebase CLI authenticated"
            else
                log_warning "Firebase CLI not authenticated"
            fi
        fi
    else
        log_warning "Firebase service account not configured"
    fi

    # Check Docker credentials
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        log_success "Docker credentials configured"
    else
        log_warning "Docker credentials not configured"
    fi

    # Check NPM token
    if [ -n "$NPM_TOKEN" ]; then
        log_success "NPM token configured"
    else
        log_warning "NPM token not configured"
    fi
}

# Generate secure tokens
generate_tokens() {
    log_header "Token Generation"

    log_info "Generating secure tokens for development..."

    echo "JWT_SECRET=$(openssl rand -hex 32)"
    echo "ENCRYPTION_KEY=$(openssl rand -hex 32)"
    echo "SESSION_SECRET=$(openssl rand -hex 32)"
    echo "API_KEY=$(openssl rand -hex 16)"

    log_warning "Save these values to .env.automation.$ENVIRONMENT"
}

# Main function
main() {
    local action="${1:-status}"

    case "$action" in
        "rotate")
            rotate_all_tokens
            ;;
        "status")
            check_token_status
            ;;
        "generate")
            generate_tokens
            ;;
        "github")
            rotate_github_token
            ;;
        "firebase")
            rotate_firebase_token
            ;;
        "docker")
            rotate_docker_token
            ;;
        "npm")
            rotate_npm_token
            ;;
        *)
            log_error "Unknown action: $action"
            echo "Usage: $0 <action>"
            echo "Actions: rotate, status, generate, github, firebase, docker, npm"
            exit 1
            ;;
    esac
}

main "$@"