#!/bin/bash
# install.sh - Main installer for Ubuntu Setup Scripts
#
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ubuntu-setup-scripts/main/install.sh | bash
#
# Or clone and run:
#   git clone https://github.com/YOUR_USERNAME/ubuntu-setup-scripts.git
#   cd ubuntu-setup-scripts
#   ./install.sh
#
# Options:
#   -h, --help          Show help
#   -i, --interactive   Interactive mode (prompts for each option)
#   -c, --config FILE   Use custom config file
#   -m, --module NAME   Install specific module only (shell, apps, docker, desktop)
#   --dry-run           Show what would be installed without making changes
#   --claude            Include Claude CLI installation

set -e

# ============================================
# Setup
# ============================================
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/RahatHameed/ubuntu-workstation"
CLONE_DIR="$HOME/.ubuntu-setup-scripts"

# Check if running from curl pipe
if [[ ! -f "$ROOT_DIR/modules/common.sh" ]]; then
    echo "Downloading ubuntu-setup-scripts..."
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
    ROOT_DIR="$CLONE_DIR"
fi

source "$ROOT_DIR/modules/common.sh"

# ============================================
# Defaults
# ============================================
INTERACTIVE=false
CONFIG_FILE=""
MODULE=""
DRY_RUN=false
INSTALL_CLAUDE=false

# ============================================
# Parse arguments
# ============================================
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Ubuntu Setup Scripts - Automated workstation setup"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -h, --help          Show this help message"
            echo "  -i, --interactive   Interactive mode (prompts for each option)"
            echo "  -c, --config FILE   Use custom config file"
            echo "  -m, --module NAME   Install specific module only"
            echo "                      Modules: shell, git, ssh, apps, docker, desktop, vpn, all"
            echo "  --dry-run           Show what would be installed"
            echo "  --claude            Include Claude CLI installation"
            echo ""
            echo "Examples:"
            echo "  $0                      # Install all with defaults"
            echo "  $0 -i                   # Interactive mode"
            echo "  $0 -m shell             # Install only Zsh + Oh My Zsh"
            echo "  $0 -c config.yaml       # Use custom config"
            echo "  $0 --dry-run            # Preview changes"
            echo ""
            echo "Quick install:"
            echo "  curl -fsSL https://raw.githubusercontent.com/RahatHameed/ubuntu-workstation/main/install.sh | bash"
            exit 0
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            export DRY_RUN
            shift
            ;;
        --claude)
            INSTALL_CLAUDE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================
# Pre-flight checks
# ============================================
check_ubuntu

print_section "Ubuntu Setup Scripts"
echo "This script will set up your Ubuntu workstation."

if [[ "$DRY_RUN" == true ]]; then
    print_warning "DRY-RUN MODE: No changes will be made"
    echo ""
fi

# ============================================
# Interactive mode
# ============================================
run_interactive() {
    print_section "Interactive Setup"

    local modules=()

    confirm "Install Zsh + Oh My Zsh?" && modules+=("shell")
    confirm "Configure Git (user, aliases)?" && modules+=("git")
    confirm "Setup SSH key + agent?" && modules+=("ssh")
    confirm "Install work applications?" && modules+=("apps")
    confirm "Install Docker?" && modules+=("docker")
    confirm "Install desktop customizations (Plank, fonts)?" && modules+=("desktop")
    confirm "Install Mullvad VPN?" && modules+=("vpn")

    echo ""

    for mod in "${modules[@]}"; do
        case "$mod" in
            shell) source "$ROOT_DIR/modules/shell.sh" && install_shell ;;
            git) source "$ROOT_DIR/modules/git.sh" && install_git ;;
            ssh) source "$ROOT_DIR/modules/ssh.sh" && install_ssh ;;
            apps) source "$ROOT_DIR/modules/apps.sh" && install_apps_interactive ;;
            docker) source "$ROOT_DIR/modules/docker.sh" && install_docker ;;
            desktop) source "$ROOT_DIR/modules/desktop.sh" && install_desktop ;;
            vpn) source "$ROOT_DIR/modules/vpn.sh" && install_vpn ;;
        esac
    done

    if confirm "Install Claude CLI?"; then
        install_claude_cli
    fi
}

# ============================================
# Install specific module
# ============================================
run_module() {
    local module="$1"

    case "$module" in
        shell)
            source "$ROOT_DIR/modules/shell.sh"
            install_shell
            ;;
        git)
            source "$ROOT_DIR/modules/git.sh"
            install_git
            ;;
        ssh)
            source "$ROOT_DIR/modules/ssh.sh"
            install_ssh
            ;;
        apps)
            source "$ROOT_DIR/modules/apps.sh"
            install_apps "$CONFIG_FILE"
            ;;
        docker)
            source "$ROOT_DIR/modules/docker.sh"
            install_docker
            ;;
        desktop)
            source "$ROOT_DIR/modules/desktop.sh"
            install_desktop "$CONFIG_FILE"
            ;;
        vpn)
            source "$ROOT_DIR/modules/vpn.sh"
            install_vpn
            ;;
        all)
            run_all
            ;;
        *)
            print_error "Unknown module: $module"
            echo "Available modules: shell, git, ssh, apps, docker, desktop, vpn, all"
            exit 1
            ;;
    esac
}

# ============================================
# Install all modules
# ============================================
run_all() {
    # System updates
    print_section "System Updates"
    run sudo apt update
    run sudo apt upgrade -y
    print_status "System updated"

    # Core packages
    print_section "Core Packages"
    apt_install git
    apt_install curl
    apt_install wget

    # Run all modules
    source "$ROOT_DIR/modules/shell.sh"
    install_shell

    source "$ROOT_DIR/modules/git.sh"
    install_git

    source "$ROOT_DIR/modules/ssh.sh"
    install_ssh

    source "$ROOT_DIR/modules/apps.sh"
    install_apps "$CONFIG_FILE"

    source "$ROOT_DIR/modules/docker.sh"
    install_docker

    source "$ROOT_DIR/modules/desktop.sh"
    install_desktop "$CONFIG_FILE"

    source "$ROOT_DIR/modules/vpn.sh"
    install_vpn
}

# ============================================
# Claude CLI installation
# ============================================
install_claude_cli() {
    if command_exists claude; then
        print_status "Claude CLI already installed"
        return 0
    fi

    print_info "Installing Claude CLI..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install Claude CLI"
    else
        curl -fsSL https://claude.ai/install.sh | sh
        print_warning "Run 'claude login' to authenticate"
    fi
    print_status "Claude CLI installed"
}

# ============================================
# Main
# ============================================
main() {
    if [[ "$INTERACTIVE" == true ]]; then
        run_interactive
    elif [[ -n "$MODULE" ]]; then
        run_module "$MODULE"
    else
        run_all
    fi

    # Optional: Claude CLI
    if [[ "$INSTALL_CLAUDE" == true ]]; then
        install_claude_cli
    fi

    # Summary
    print_section "Setup Complete!"

    echo "Installed components:"
    [[ -z "$MODULE" || "$MODULE" == "shell" || "$MODULE" == "all" ]] && echo "  - Zsh + Oh My Zsh"
    [[ -z "$MODULE" || "$MODULE" == "git" || "$MODULE" == "all" ]] && echo "  - Git configuration"
    [[ -z "$MODULE" || "$MODULE" == "ssh" || "$MODULE" == "all" ]] && echo "  - SSH key + agent"
    [[ -z "$MODULE" || "$MODULE" == "apps" || "$MODULE" == "all" ]] && echo "  - Work applications"
    [[ -z "$MODULE" || "$MODULE" == "docker" || "$MODULE" == "all" ]] && echo "  - Docker Engine + Desktop"
    [[ -z "$MODULE" || "$MODULE" == "desktop" || "$MODULE" == "all" ]] && echo "  - Desktop customizations"
    [[ -z "$MODULE" || "$MODULE" == "vpn" || "$MODULE" == "all" ]] && echo "  - Mullvad VPN"

    echo ""
    echo "Next steps:"
    echo "  1. Log out and back in for all changes to take effect"
    echo "  2. Configure Plank dock (Ctrl + right-click)"
    echo "  3. Apply theme in GNOME Tweaks (if installed)"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY-RUN: No changes were made"
    fi
}

main
