#!/bin/bash

# Act Workflow Testing Script
# Test GitHub Actions workflows locally with act to avoid consuming Actions minutes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎭 Act Workflow Testing${NC}"
echo -e "${BLUE}========================${NC}"

cd "$PROJECT_ROOT"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

    # Check if act is installed
    if ! command -v act &> /dev/null; then
        echo -e "${RED}❌ act CLI is not installed${NC}"
        echo -e "${YELLOW}Install with: brew install act${NC}"
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker is not running${NC}"
        echo -e "${YELLOW}Start Docker Desktop and try again${NC}"
        exit 1
    fi

    # Check for .act-secrets
    if [ ! -f ".act-secrets/test-secrets" ]; then
        echo -e "${YELLOW}Creating test secrets file...${NC}"
        mkdir -p .act-secrets
        cat > .act-secrets/test-secrets << EOF
FIREBASE_TOKEN=test_token_replace_with_real
FIREBASE_SERVICE_ACCOUNT_KEY={"test": "key_replace_with_real"}
EOF
        echo -e "${YELLOW}⚠️  Update .act-secrets/test-secrets with real values${NC}"
    fi

    echo -e "${GREEN}✅ Prerequisites met${NC}"
}

# Setup Docker images (one-time setup)
setup_docker_images() {
    echo -e "${YELLOW}🐳 Setting up Docker images for act...${NC}"

    # Pull required images
    docker pull catthehacker/ubuntu:act-latest || echo "Failed to pull act image"
    docker pull node:18 || echo "Failed to pull Node.js image"
    docker pull cimg/android:2023.10 || echo "Failed to pull Android image"

    echo -e "${GREEN}✅ Docker images setup${NC}"
}

# Test specific workflow
test_workflow() {
    local workflow="$1"
    local job="$2"
    local event="${3:-push}"

    echo -e "${YELLOW}🧪 Testing workflow: $workflow${NC}"
    echo -e "${YELLOW}Job: $job${NC}"
    echo -e "${YELLOW}Event: $event${NC}"
    echo ""

    # Common act options
    local act_cmd="act -W .github/workflows/$workflow.yml"
    act_cmd="$act_cmd --secret-file .act-secrets/test-secrets"
    act_cmd="$act_cmd --job $job"
    act_cmd="$act_cmd --container-architecture linux/amd64"
    act_cmd="$act_cmd --pull=false"

    # Add event-specific options
    case $event in
        "push")
            act_cmd="$act_cmd --eventpath .github/workflows/test-events/push.json"
            ;;
        "workflow_dispatch")
            act_cmd="$act_cmd --eventpath .github/workflows/test-events/workflow_dispatch.json"
            ;;
    esac

    echo "Running: $act_cmd"
    echo ""

    if eval "$act_cmd"; then
        echo -e "${GREEN}✅ Workflow test passed${NC}"
    else
        echo -e "${RED}❌ Workflow test failed${NC}"
        echo -e "${YELLOW}💡 This is expected - fix issues locally before pushing to GitHub${NC}"
    fi
}

# Create test event files
create_test_events() {
    echo -e "${YELLOW}📝 Creating test event files...${NC}"

    mkdir -p .github/workflows/test-events

    # Push event
    cat > .github/workflows/test-events/push.json << EOF
{
  "push": {
    "ref": "refs/heads/develop",
    "head_commit": {
      "message": "Test commit [DRY-RUN]"
    }
  }
}
EOF

    # Workflow dispatch event
    cat > .github/workflows/test-events/workflow_dispatch.json << EOF
{
  "inputs": {
    "environment": "development",
    "dry_run": "true"
  }
}
EOF

    echo -e "${GREEN}✅ Test event files created${NC}"
}

# Main menu
main_menu() {
    echo ""
    echo -e "${BLUE}Choose workflow to test:${NC}"
    echo "1. 🚀 CI/CD Pipeline - Quality Check"
    echo "2. 🚀 CI/CD Pipeline - Build Web"
    echo "3. 🚀 CI/CD Pipeline - Deploy Web"
    echo "4. 📱 Android Distribution"
    echo "5. 🍎 iOS Distribution"
    echo "6. 🌐 Web Deployment"
    echo "7. 🔐 Test Secrets"
    echo "8. 🐳 Setup Docker Images (one-time)"
    echo "9. 📝 Create Test Events"
    echo "0. Exit"
    echo ""

    read -p "Enter choice (0-9): " choice

    case $choice in
        1)
            test_workflow "ci-cd-pipeline" "quality-check" "push"
            ;;
        2)
            test_workflow "ci-cd-pipeline" "build-web" "workflow_dispatch"
            ;;
        3)
            test_workflow "ci-cd-pipeline" "deploy-web" "workflow_dispatch"
            ;;
        4)
            test_workflow "android-distribution" "distribute-android" "push"
            ;;
        5)
            test_workflow "ios-distribution" "distribute-ios" "push"
            ;;
        6)
            test_workflow "web-deployment" "deploy-web" "push"
            ;;
        7)
            test_workflow "test-secrets" "test-secrets" "workflow_dispatch"
            ;;
        8)
            setup_docker_images
            ;;
        9)
            create_test_events
            ;;
        0)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            ;;
    esac

    # Loop back to menu
    main_menu
}

# Run main function
check_prerequisites
main_menu