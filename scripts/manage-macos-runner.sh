#!/bin/bash
# manage-macos-runner.sh
# Script to manage self-hosted macOS runner for GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
RUNNER_VERSION="2.329.0"
RUNNER_DIR="$HOME/actions-runner"
REPO_URL="https://github.com/mnelson3/modulo-squares"
RUNNER_NAME="macos-runner-$(hostname)"

echo -e "${BLUE}🍎 macOS Runner Manager${NC}"
echo -e "${BLUE}=====================${NC}"

# Function to get GitHub token
get_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${YELLOW}🔑 Enter your GitHub Personal Access Token:${NC}"
        echo -e "${YELLOW}   (Create one at: https://github.com/settings/tokens)${NC}"
        echo -e "${YELLOW}   Required scopes: repo, workflow${NC}"
        read -s GITHUB_TOKEN
        echo ""
    fi
}

# Configure runner
configure() {
    echo -e "${YELLOW}⚙️  Configuring runner...${NC}"

    get_token

    # Clean up existing runner
    if [ -d "$RUNNER_DIR" ]; then
        echo -e "${YELLOW}🧹 Cleaning up existing runner...${NC}"
        cd "$RUNNER_DIR"
        ./svc.sh stop 2>/dev/null || true
        ./svc.sh uninstall 2>/dev/null || true
        cd ..
        rm -rf "$RUNNER_DIR"
    fi

    # Download and extract runner
    echo -e "${YELLOW}📥 Downloading runner...${NC}"
    mkdir -p "$RUNNER_DIR"
    cd "$RUNNER_DIR"

    curl -o "actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz" \
         -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"

    tar xzf "actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"
    rm "actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"

    # Configure runner
    echo -e "${YELLOW}🔧 Configuring runner...${NC}"
    ./config.sh --url "$REPO_URL" --token "$GITHUB_TOKEN" --name "$RUNNER_NAME" --labels "self-hosted,macOS,arm64" --unattended

    echo -e "${GREEN}✅ Runner configured successfully!${NC}"
}

# Install as service
install() {
    echo -e "${YELLOW}🔧 Installing as service...${NC}"

    if [ ! -d "$RUNNER_DIR" ]; then
        echo -e "${RED}❌ Runner not configured. Run 'configure' first.${NC}"
        exit 1
    fi

    cd "$RUNNER_DIR"
    ./svc.sh install
    echo -e "${GREEN}✅ Runner installed as service!${NC}"
}

# Start runner
start() {
    echo -e "${YELLOW}🚀 Starting runner...${NC}"

    if [ ! -d "$RUNNER_DIR" ]; then
        echo -e "${RED}❌ Runner not configured. Run 'configure' first.${NC}"
        exit 1
    fi

    cd "$RUNNER_DIR"
    ./svc.sh start
    echo -e "${GREEN}✅ Runner started!${NC}"
}

# Stop runner
stop() {
    echo -e "${YELLOW}⏹️  Stopping runner...${NC}"

    if [ ! -d "$RUNNER_DIR" ]; then
        echo -e "${RED}❌ Runner not configured.${NC}"
        return
    fi

    cd "$RUNNER_DIR"
    ./svc.sh stop 2>/dev/null || true
    echo -e "${GREEN}✅ Runner stopped!${NC}"
}

# Uninstall runner
uninstall() {
    echo -e "${YELLOW}🗑️  Uninstalling runner...${NC}"

    if [ ! -d "$RUNNER_DIR" ]; then
        echo -e "${RED}❌ Runner not configured.${NC}"
        return
    fi

    cd "$RUNNER_DIR"
    ./svc.sh stop 2>/dev/null || true
    ./svc.sh uninstall 2>/dev/null || true
    cd ..
    rm -rf "$RUNNER_DIR"
    echo -e "${GREEN}✅ Runner uninstalled!${NC}"
}

# Show status
status() {
    echo -e "${BLUE}📊 Runner Status${NC}"
    echo -e "${BLUE}==============${NC}"

    if [ ! -d "$RUNNER_DIR" ]; then
        echo -e "${RED}❌ Runner not installed${NC}"
        return
    fi

    cd "$RUNNER_DIR"

    # Check if service is running
    if pgrep -f "Runner.Listener" > /dev/null; then
        echo -e "${GREEN}✅ Runner service is running${NC}"
    else
        echo -e "${RED}❌ Runner service is not running${NC}"
    fi

    # Show runner info
    if [ -f ".runner" ]; then
        echo -e "${YELLOW}📋 Runner Info:${NC}"
        cat .runner | grep -E "(name|labels|version)" | sed 's/^/  /'
    fi
}

# Show logs
logs() {
    echo -e "${BLUE}📋 Runner Logs${NC}"
    echo -e "${BLUE}============${NC}"

    if [ ! -d "$RUNNER_DIR" ]; then
        echo -e "${RED}❌ Runner not installed${NC}"
        return
    fi

    cd "$RUNNER_DIR"
    tail -n 50 _diag/*.log 2>/dev/null || echo "No logs found"
}

# Update runner
update() {
    echo -e "${YELLOW}🔄 Updating runner...${NC}"

    stop
    uninstall
    configure
    install
    start

    echo -e "${GREEN}✅ Runner updated successfully!${NC}"
}

# Main command handling
case "${1:-status}" in
    configure)
        configure
        ;;
    install)
        install
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    uninstall)
        uninstall
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    update)
        update
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        echo -e "${YELLOW}📋 Available commands:${NC}"
        echo "  configure  - Configure the runner"
        echo "  install    - Install as system service"
        echo "  start      - Start the runner service"
        echo "  stop       - Stop the runner service"
        echo "  uninstall  - Remove the runner completely"
        echo "  status     - Show runner status"
        echo "  logs       - Show runner logs"
        echo "  update     - Update to latest runner version"
        exit 1
        ;;
esac