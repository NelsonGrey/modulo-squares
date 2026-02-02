#!/bin/bash
# 📊 Monitoring & Alerting System

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
MONITOR_INTERVAL="${MONITOR_INTERVAL:-300}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
LOG_FILE="${LOG_FILE:-monitoring.log}"
HEALTH_FILE="${HEALTH_FILE:-health-status.json}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

# Helper functions
log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$LOG_FILE"; }
log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" | tee -a "$LOG_FILE"; }
log_warning() { echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" | tee -a "$LOG_FILE"; }
log_error() { echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$LOG_FILE"; }
log_header() { echo -e "${PURPLE}📊 $1${NC}"; echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"; }

# CRITICAL: Bash 3.2 compatibility - NO associative arrays
# Use variable naming: ENDPOINTS_<environment>
ENDPOINTS_development="http://localhost:5001/modulo-squares-dev/us-central1/api"
ENDPOINTS_staging="https://us-central1-modulo-squares-staging.cloudfunctions.net/api"
ENDPOINTS_production="https://us-central1-modulo-squares-prod.cloudfunctions.net/api"

# Send alerts
send_alert() {
    local level="$1"; local service="$2"; local message="$3"; local details="$4"

    # Email alert
    if [ -n "$ALERT_EMAIL" ]; then
        log_info "Sending email alert to $ALERT_EMAIL"
        # Email implementation would go here
    fi

    # Slack alert
    if [ -n "$SLACK_WEBHOOK" ]; then
        log_info "Sending Slack alert"
        # Slack implementation would go here
    fi
}

# System monitoring
monitor_system_resources() {
    log_info "Monitoring system resources..."

    # CPU usage
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    log_info "CPU usage: ${cpu_usage}%"

    # Memory usage
    local mem_usage
    mem_usage=$(top -l 1 | grep "PhysMem" | awk '{print $2}' | sed 's/M//')
    log_info "Memory usage: ${mem_usage}MB"

    # Disk usage
    local disk_usage
    disk_usage=$(df -h "$PROJECT_ROOT" | tail -1 | awk '{print $5}' | sed 's/%//')
    log_info "Disk usage: ${disk_usage}%"

    # Alert thresholds
    if [ "${cpu_usage%.*}" -gt 90 ]; then
        send_alert "CRITICAL" "System" "High CPU usage" "CPU: ${cpu_usage}%"
    fi

    if [ "${disk_usage%.*}" -gt 90 ]; then
        send_alert "CRITICAL" "System" "High disk usage" "Disk: ${disk_usage}%"
    fi
}

# GitHub monitoring (with auth check)
monitor_github_actions() {
    log_info "Monitoring GitHub Actions..."
    if ! gh auth status > /dev/null 2>&1; then
        log_warning "GitHub CLI not authenticated - skipping GitHub Actions monitoring"
        return
    fi

    # Check recent workflow runs
    local repo="${GITHUB_REPO:-mnelson3/modulo-squares}"
    local recent_runs
    recent_runs=$(gh run list --repo "$repo" --limit 5 --json status,conclusion,createdAt | jq -r '.[] | "\(.status) \(.conclusion) \(.createdAt)"')

    echo "$recent_runs" | while read -r status conclusion created; do
        log_info "Workflow run: $status $conclusion ($created)"
        if [ "$status" = "completed" ] && [ "$conclusion" = "failure" ]; then
            send_alert "WARNING" "GitHub Actions" "Workflow failure detected" "Status: $status, Conclusion: $conclusion"
        fi
    done
}

# Firebase monitoring
monitor_firebase() {
    log_info "Monitoring Firebase services..."

    if ! command -v firebase > /dev/null 2>&1; then
        log_warning "Firebase CLI not installed - skipping Firebase monitoring"
        return
    fi

    # Check Firebase projects
    if firebase projects:list > /dev/null 2>&1; then
        log_success "Firebase CLI authenticated"
    else
        log_error "Firebase CLI not authenticated"
        send_alert "ERROR" "Firebase" "CLI authentication failed" "Unable to access Firebase services"
    fi
}

# API endpoint monitoring
monitor_api_endpoints() {
    log_info "Monitoring API endpoints..."

    # Get current environment endpoints
    local endpoints
    endpoints=$(eval "echo \$ENDPOINTS_$ENVIRONMENT")

    if [ -z "$endpoints" ]; then
        log_warning "No API endpoints configured for $ENVIRONMENT"
        return
    fi

    # Test endpoint health
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoints/health" 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        log_success "API endpoint healthy: $endpoints"
    else
        log_error "API endpoint unhealthy: $endpoints (HTTP $response)"
        send_alert "ERROR" "API" "Endpoint health check failed" "URL: $endpoints, Response: $response"
    fi
}

# Update health status
update_health_status() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local health_data
    health_data=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "environment": "$ENVIRONMENT",
  "system": {
    "cpu": "$(top -l 1 | grep "CPU usage" | awk '{print $3}')",
    "memory": "$(top -l 1 | grep "PhysMem" | awk '{print $2}')",
    "disk": "$(df -h "$PROJECT_ROOT" | tail -1 | awk '{print $5}')"
  },
  "services": {
    "github_authenticated": $(gh auth status > /dev/null 2>&1 && echo "true" || echo "false"),
    "firebase_available": $(firebase projects:list > /dev/null 2>&1 && echo "true" || echo "false")
  }
}
EOF
)

    echo "$health_data" | jq . > "$HEALTH_FILE"
    log_info "Health status updated"
}

# Main monitoring loop
main() {
    log_header "🚀 Modulo Squares - Monitoring & Alerting System"

    cd "$PROJECT_ROOT"

    # Initialize health file
    if [ ! -f "$HEALTH_FILE" ]; then
        echo '{"initialized": true, "timestamp": "'$(date)'"}' | jq . > "$HEALTH_FILE"
    fi

    # Load environment
    ENVIRONMENT="${ENVIRONMENT:-development}"
    if [ -f ".env.automation.$ENVIRONMENT" ]; then source ".env.automation.$ENVIRONMENT"; fi

    # Single run or continuous
    if [ "${1:-}" = "--once" ]; then
        log_info "Running single monitoring cycle..."

        monitor_system_resources
        monitor_github_actions
        monitor_firebase
        monitor_api_endpoints
        update_health_status

        log_success "Monitoring cycle completed"
    else
        log_info "Starting continuous monitoring (interval: ${MONITOR_INTERVAL}s)..."

        while true; do
            monitor_system_resources
            monitor_github_actions
            monitor_firebase
            monitor_api_endpoints
            update_health_status

            sleep "$MONITOR_INTERVAL"
        done
    fi
}

main "$@"