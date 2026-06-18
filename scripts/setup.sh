#!/bin/bash
# Unified Setup Script for Modulo Project
# Combines common setup operations

set -e

show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  env [environment]    - Setup environment variables"
    echo "  firebase             - Setup Firebase configuration"
    echo "  ios                  - Setup iOS certificates and provisioning"
    echo "  macos                - Setup macOS runner"
    echo "  all                  - Run all setup steps"
    echo "  help                 - Show this help"
}

setup_env() {
    local env=${1:-dev}
    echo "Setting up environment: $env"
    ./scripts/setup-env.sh "$env"
}

setup_firebase() {
    echo "Setting up Firebase"
    ./scripts/setup-firebase.sh
}

setup_ios() {
    echo "Setting up iOS certificates"
    ./scripts/setup-ios-certificates.sh
}

setup_macos() {
    echo "Setting up macOS runner"
    ./scripts/setup-macos-runner.sh
}

setup_all() {
    setup_env
    setup_firebase
    setup_ios
    setup_macos
}

case "${1:-help}" in
    env)
        setup_env "$2"
        ;;
    firebase)
        setup_firebase
        ;;
    ios)
        setup_ios
        ;;
    macos)
        setup_macos
        ;;
    all)
        setup_all
        ;;
    help|*)
        show_help
        ;;
esac
