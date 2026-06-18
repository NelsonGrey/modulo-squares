#!/bin/bash

# Infrastructure Status Summary for Modulo Squares
# Shows current state of self-hosted runners and workflows

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/mnelson3/modulo-squares"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

header() {
    echo -e "${PURPLE}================================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================================${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check Docker runner status
check_docker_runner() {
    header "🐳 Docker Runner Status"

    if [ ! -f "docker-compose.runner.yml" ]; then
        warning "docker-compose.runner.yml not found"
        return
    fi

    if [ ! -f ".env.runner" ]; then
        warning ".env.runner file not found"
        info "Run: cp .env.runner.template .env.runner && edit with your token"
        echo ""
        return
    fi

    if docker compose -f docker-compose.runner.yml ps 2>/dev/null | grep -q "Up"; then
        success "Docker runner is running"

        # Show container details
        echo ""
        info "Container Details:"
        docker compose -f docker-compose.runner.yml ps

        # Check runner registration
        if docker compose -f docker-compose.runner.yml logs 2>/dev/null | grep -q "Runner successfully added"; then
            success "Runner is registered with GitHub"
        else
            warning "Runner may not be registered - check logs"
        fi

    else
        warning "Docker runner is not running"
        info "Start with: ./scripts/manage-docker-runner.sh start"
    fi

    echo ""
}

# Check macOS runner status
check_macos_runner() {
    header "🍎 macOS Runner Status"

    # Check if macOS runner service exists
    if pgrep -f "Runner.Listener" > /dev/null 2>&1; then
        success "macOS runner service is running"

        # Check if configured for this repo (custom directory location)
        if [ -d "/Users/marknelson/Circus/Repositories/modulo-squares-actions-runner" ]; then
            success "macOS runner directory exists"

            # Check configuration
            if [ -f "/Users/marknelson/Circus/Repositories/modulo-squares-actions-runner/.runner" ]; then
                success "macOS runner is configured"
            else
                warning "macOS runner is not configured"
                info "Configure with: ./scripts/manage-macos-runner.sh configure"
            fi
        else
            warning "macOS runner directory not found"
            info "Set up with: ./scripts/setup-macos-runner.sh"
        fi

    else
        warning "macOS runner service is not running"
        info "Set up with: ./scripts/setup-macos-runner.sh"
        echo ""
        return
    fi

    echo ""
}

# Check workflow status
check_workflows() {
    header "🔄 Workflow Status"

    local workflow_dir="$PROJECT_ROOT/.github/workflows"

    if [ ! -d "$workflow_dir" ]; then
        error "Workflows directory not found"
        return 1
    fi

    echo -e "${CYAN}Workflow configurations:${NC}"
    echo ""

    # Check each workflow
    for workflow in "$workflow_dir"/*.yml; do
        if [ -f "$workflow" ]; then
            local name=$(basename "$workflow" .yml)
            echo -e "${YELLOW}$name:${NC}"

            # Check runner configuration
            if grep -q "runs-on:.*self-hosted" "$workflow"; then
                success "  Uses self-hosted runners"
            elif grep -q "runs-on:.*macos" "$workflow" && grep -q "self-hosted" "$workflow"; then
                success "  Uses self-hosted macOS runners"
            elif grep -q "runs-on:.*macos" "$workflow"; then
                warning "  Uses GitHub-hosted macOS runners (costs apply)"
            else
                info "  Uses GitHub-hosted runners"
            fi

            # Check if enabled
            if grep -q "workflow_dispatch:" "$workflow" || grep -q "push:" "$workflow" || grep -q "pull_request:" "$workflow"; then
                success "  Workflow is enabled"
            else
                warning "  Workflow may be disabled"
            fi

            echo ""
        fi
    done
}

# Cost analysis
cost_analysis() {
    header "💰 Cost Analysis"

    # Run the cost monitoring script if available
    if [ -f "./scripts/monitor-github-actions-costs.sh" ]; then
        echo -e "${CYAN}GitHub Actions costs (last 30 days):${NC}"
        ./scripts/monitor-github-actions-costs.sh 1 2>/dev/null | tail -10
    else
        warning "Cost monitoring script not found"
    fi

    echo ""
}

# Recommendations
recommendations() {
    header "💡 Recommendations"

    local has_docker_runner=false
    local has_macos_runner=false

    # Check runner status
    if docker compose -f docker-compose.runner.yml ps 2>/dev/null | grep -q "Up"; then
        has_docker_runner=true
    fi

    if pgrep -f "Runner.Listener" > /dev/null 2>&1; then
        has_macos_runner=true
    fi

    if [ "$has_docker_runner" = false ]; then
        warning "Set up Docker runner for Linux builds"
        info "  Run: ./scripts/manage-docker-runner.sh setup"
        echo ""
    fi

    if [ "$has_macos_runner" = false ]; then
        warning "Set up macOS runner for iOS builds"
        info "  Run: ./scripts/setup-macos-runner.sh"
        info "  Then: ./scripts/manage-macos-runner.sh configure"
        echo ""
    fi

    if [ "$has_docker_runner" = true ] && [ "$has_macos_runner" = true ]; then
        success "All runners configured! 🎉"
        info "Monitor costs at: https://github.com/settings/billing"
        echo ""
    fi

    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Update Linux runner token with real GitHub token"
    echo "2. Test workflows with self-hosted runners"
    echo "3. Monitor GitHub billing for cost reductions"
    echo "4. Update team on infrastructure changes"
    echo ""
}

# Main function
main() {
    header "🏗️  Modulo Squares Infrastructure Status"

    echo -e "${CYAN}Repository: $REPO_URL${NC}"
    echo -e "${CYAN}Date: $(date)${NC}"
    echo ""

    check_docker_runner
    check_macos_runner
    check_workflows
    cost_analysis
    recommendations

    header "📚 Resources"
    echo -e "${CYAN}Documentation:${NC}"
    echo "  Linux Runner: ./scripts/setup-self-hosted-runner.sh --help"
    echo "  macOS Runner: ./docs/SELF_HOSTED_RUNNERS.md"
    echo "  Management: ./scripts/manage-*-runner.sh"
    echo ""
    echo -e "${CYAN}GitHub Settings:${NC}"
    echo "  Runners: $REPO_URL/settings/actions/runners"
    echo "  Billing: https://github.com/settings/billing"
    echo ""
}

# Run main function
main "$@"