#!/bin/bash
# uninstall.sh - Uninstall/revert Ubuntu Setup Scripts changes
#
# Usage:
#   ./uninstall.sh              # Interactive mode
#   ./uninstall.sh -m shell     # Uninstall specific module
#   ./uninstall.sh --all        # Uninstall everything
#   ./uninstall.sh --dry-run    # Preview changes

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/modules/common.sh"

# Defaults
DRY_RUN=false
MODULE=""
UNINSTALL_ALL=false

# ============================================
# Parse arguments
# ============================================
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Ubuntu Setup Scripts - Uninstaller"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -h, --help          Show this help message"
            echo "  -m, --module NAME   Uninstall specific module"
            echo "                      Modules: shell, git, ssh, apps, docker, desktop, startup, darkmode, vpn"
            echo "  --all               Uninstall everything"
            echo "  --dry-run           Show what would be removed"
            echo ""
            echo "Examples:"
            echo "  $0                   # Interactive mode"
            echo "  $0 -m apps           # Uninstall only apps"
            echo "  $0 --all --dry-run   # Preview full uninstall"
            exit 0
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        --all)
            UNINSTALL_ALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            export DRY_RUN
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================
# Uninstall functions
# ============================================

uninstall_shell() {
    print_section "Uninstalling Shell (Zsh + Oh My Zsh)"

    # Revert to bash
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_info "Reverting default shell to bash..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would run: chsh -s /bin/bash"
        else
            chsh -s /bin/bash
            print_status "Default shell reverted to bash"
        fi
    else
        print_status "Shell is already bash"
    fi

    # Remove Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Removing Oh My Zsh..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove ~/.oh-my-zsh"
        else
            rm -rf "$HOME/.oh-my-zsh"
            print_status "Oh My Zsh removed"
        fi
    fi

    # Remove .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        print_info "Removing .zshrc..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove ~/.zshrc"
        else
            rm -f "$HOME/.zshrc"
            print_status ".zshrc removed"
        fi
    fi

    print_warning "Zsh package kept (remove manually: sudo apt remove zsh)"
}

uninstall_git() {
    print_section "Uninstalling Git Configuration"

    print_info "Removing git aliases..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would remove git aliases"
    else
        git config --global --remove-section alias 2>/dev/null || true
        print_status "Git aliases removed"
    fi

    print_warning "Git user.name and user.email kept (remove manually if needed)"
    print_warning "Git package kept (remove manually: sudo apt remove git)"
}

uninstall_ssh() {
    print_section "Uninstalling SSH Configuration"

    # Remove SSH agent config from shell
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc_file" ]] && grep -q "SSH Agent" "$rc_file"; then
            print_info "Removing SSH agent config from $rc_file..."
            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would remove SSH agent config from $rc_file"
            else
                sed -i '/# SSH Agent/,/ssh-add.*2>\/dev\/null/d' "$rc_file"
                print_status "SSH agent config removed from $rc_file"
            fi
        fi
    done

    # Remove SSH config entries (keep file, remove our additions)
    if [[ -f "$HOME/.ssh/config" ]]; then
        print_info "Removing GitHub/GitLab entries from SSH config..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove GitHub/GitLab entries from ~/.ssh/config"
        else
            sed -i '/# Global SSH settings/,/IdentityFile.*id_ed25519/d' "$HOME/.ssh/config"
            print_status "SSH config entries removed"
        fi
    fi

    print_warning "SSH keys kept for safety (remove manually: rm ~/.ssh/id_ed25519*)"
}

uninstall_apps() {
    print_section "Uninstalling Applications"

    # Snap apps
    local snap_apps=("slack" "teams-for-linux" "code" "spotify" "discord" "postman" "dbeaver-ce")
    for app in "${snap_apps[@]}"; do
        if snap_installed "$app"; then
            print_info "Removing $app..."
            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY-RUN] Would run: sudo snap remove $app"
            else
                sudo snap remove "$app"
                print_status "$app removed"
            fi
        fi
    done

    # Chrome
    if command_exists google-chrome; then
        print_info "Removing Google Chrome..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would run: sudo apt remove google-chrome-stable"
        else
            sudo apt remove -y google-chrome-stable
            print_status "Google Chrome removed"
        fi
    fi

    # JetBrains Toolbox
    if [[ -d "$HOME/.local/share/JetBrains/Toolbox" ]]; then
        print_info "Removing JetBrains Toolbox..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove JetBrains Toolbox"
        else
            rm -rf "$HOME/.local/share/JetBrains"
            rm -rf "$HOME/.local/opt/jetbrains-toolbox"
            rm -f "$HOME/.local/bin/jetbrains-toolbox"
            rm -f "$HOME/.local/share/applications/jetbrains-toolbox.desktop"
            print_status "JetBrains Toolbox removed"
        fi
    fi

    print_warning "IDEs installed via Toolbox must be removed from Toolbox first"
}

uninstall_docker() {
    print_section "Uninstalling Docker"

    # Stop Docker services
    print_info "Stopping Docker services..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would stop Docker services"
    else
        sudo systemctl stop docker.socket docker.service 2>/dev/null || true
        systemctl --user stop docker-desktop 2>/dev/null || true
    fi

    # Remove Docker Desktop
    if [[ -f /opt/docker-desktop/bin/docker-desktop ]]; then
        print_info "Removing Docker Desktop..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove Docker Desktop"
        else
            sudo apt remove -y docker-desktop 2>/dev/null || true
            rm -rf "$HOME/.docker/desktop"
            print_status "Docker Desktop removed"
        fi
    fi

    # Remove Docker Engine
    if command_exists docker; then
        print_info "Removing Docker Engine..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove Docker packages"
        else
            sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
            sudo rm -rf /var/lib/docker /var/lib/containerd
            print_status "Docker Engine removed"
        fi
    fi

    print_warning "Docker data removed. This cannot be undone!"
}

uninstall_startup() {
    print_section "Uninstalling Startup Applications"

    if [[ -f "$HOME/.config/autostart/startup-office.desktop" ]]; then
        print_info "Removing startup entry..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove startup-office.desktop"
        else
            rm -f "$HOME/.config/autostart/startup-office.desktop"
            print_status "Startup entry removed"
        fi
    else
        print_status "No startup entry found"
    fi
}

uninstall_darkmode() {
    print_section "Uninstalling Dark Mode at Sunset"

    local unit_dir="$HOME/.config/systemd/user"

    # Stop the timer before removing the script it runs, or a tick landing
    # mid-uninstall logs a failure for a unit that is on its way out anyway.
    if systemctl --user list-unit-files dark-at-sunset.timer &>/dev/null; then
        print_info "Stopping the timer..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would disable dark-at-sunset.timer"
        else
            systemctl --user disable --now dark-at-sunset.timer 2>/dev/null || true
            print_status "Timer stopped"
        fi
    fi

    if [[ -f "$unit_dir/dark-at-sunset.timer" || -f "$unit_dir/dark-at-sunset.service" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove dark-at-sunset.{service,timer}"
        else
            rm -f "$unit_dir/dark-at-sunset.timer" "$unit_dir/dark-at-sunset.service"
            systemctl --user daemon-reload
            print_status "Units removed"
        fi
    fi

    if [[ -f "$HOME/.local/bin/dark-at-sunset" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove ~/.local/bin/dark-at-sunset"
        else
            rm -f "$HOME/.local/bin/dark-at-sunset"
            print_status "dark-at-sunset removed"
        fi
    fi

    # Ubuntu's own default, not what the module found: whatever the terminal
    # was pinned to before, 'system' is the sane state to leave behind now that
    # nothing is automating the colour scheme.
    if gsettings writable org.gnome.Terminal.Legacy.Settings theme-variant &>/dev/null; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would leave GNOME Terminal's theme variant at 'system'"
        else
            gsettings set org.gnome.Terminal.Legacy.Settings theme-variant "'system'" 2>/dev/null || true
            print_status "GNOME Terminal left following the system theme"
        fi
    fi

    # The colour scheme itself is deliberately left as-is: it is an ordinary
    # desktop preference the user can change in Settings, and forcing it back to
    # light during the evening would be a worse surprise than leaving it.
    print_warning "Colour scheme left as it is (change it in Settings > Appearance)"
    print_warning "Claude Code's theme left as it is (change it with /theme)"
}

uninstall_desktop() {
    print_section "Uninstalling Desktop Customizations"

    uninstall_startup

    # Remove Plank autostart
    if [[ -f "$HOME/.config/autostart/plank.desktop" ]]; then
        print_info "Removing Plank autostart..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would remove Plank autostart"
        else
            rm -f "$HOME/.config/autostart/plank.desktop"
            print_status "Plank autostart removed"
        fi
    fi

    # Kill Plank if running
    pkill plank 2>/dev/null || true

    # Re-enable Ubuntu Dock
    print_info "Re-enabling Ubuntu Dock..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would enable Ubuntu Dock"
    else
        gnome-extensions enable ubuntu-dock@ubuntu.com 2>/dev/null || true
        print_status "Ubuntu Dock enabled"
    fi

    # Reset font scaling
    print_info "Resetting font scaling..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would reset font scaling to 1.0"
    else
        gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
        print_status "Font scaling reset to 1.0"
    fi

    print_warning "Plank package kept (remove manually: sudo apt remove plank)"
    print_warning "Fonts kept (remove manually: sudo apt remove fonts-inter fonts-roboto)"
}

uninstall_vpn() {
    print_section "Uninstalling VPN"

    local vpn_found=false

    # Mullvad
    if command_exists mullvad; then
        vpn_found=true
        print_info "Removing Mullvad VPN..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would disconnect and remove Mullvad VPN"
        else
            mullvad disconnect 2>/dev/null || true
            run sudo apt remove -y mullvad-vpn
            sudo rm -f /etc/apt/sources.list.d/mullvad.list
            sudo rm -f /usr/share/keyrings/mullvad-keyring.asc
            print_status "Mullvad VPN removed"
        fi
    fi

    # NordVPN
    if command_exists nordvpn; then
        vpn_found=true
        print_info "Removing NordVPN..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would disconnect and remove NordVPN"
        else
            nordvpn disconnect 2>/dev/null || true
            run sudo apt remove -y nordvpn
            print_status "NordVPN removed"
        fi
    fi

    # ProtonVPN
    if command_exists protonvpn-cli; then
        vpn_found=true
        print_info "Removing ProtonVPN..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would disconnect and remove ProtonVPN"
        else
            protonvpn-cli disconnect 2>/dev/null || true
            run sudo apt remove -y protonvpn-gnome-desktop protonvpn-cli
            print_status "ProtonVPN removed"
        fi
    fi

    if [[ "$vpn_found" == false ]]; then
        print_status "No VPN installed"
    fi
}

# ============================================
# Interactive mode
# ============================================
run_interactive() {
    print_section "Interactive Uninstall"

    print_warning "This will remove components installed by Ubuntu Setup Scripts"
    echo ""

    confirm "Uninstall Zsh + Oh My Zsh?" && uninstall_shell
    confirm "Remove Git aliases?" && uninstall_git
    confirm "Remove SSH configuration?" && uninstall_ssh
    confirm "Uninstall applications (Chrome, Slack, etc.)?" && uninstall_apps
    confirm "Uninstall Docker?" && uninstall_docker
    confirm "Remove desktop customizations?" && uninstall_desktop
    confirm "Remove login autostart entry?" && uninstall_startup
    confirm "Stop following the sun for dark mode?" && uninstall_darkmode
    confirm "Uninstall Mullvad VPN?" && uninstall_vpn
}

# ============================================
# Run specific module
# ============================================
run_module() {
    case "$MODULE" in
        shell) uninstall_shell ;;
        git) uninstall_git ;;
        ssh) uninstall_ssh ;;
        apps) uninstall_apps ;;
        docker) uninstall_docker ;;
        desktop) uninstall_desktop ;;
        startup) uninstall_startup ;;
        darkmode) uninstall_darkmode ;;
        vpn) uninstall_vpn ;;
        *)
            print_error "Unknown module: $MODULE"
            echo "Available modules: shell, git, ssh, apps, docker, desktop, startup, darkmode, vpn"
            exit 1
            ;;
    esac
}

# ============================================
# Uninstall all
# ============================================
run_all() {
    print_warning "This will remove ALL components installed by Ubuntu Setup Scripts"
    echo ""

    if [[ "$DRY_RUN" != true ]]; then
        if ! confirm "Are you sure you want to continue?"; then
            echo "Aborted."
            exit 0
        fi
    fi

    uninstall_vpn
    uninstall_darkmode
    uninstall_desktop
    uninstall_apps
    uninstall_docker
    uninstall_ssh
    uninstall_git
    uninstall_shell
}

# ============================================
# Main
# ============================================
main() {
    print_section "Ubuntu Setup Scripts - Uninstaller"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY-RUN MODE: No changes will be made"
        echo ""
    fi

    if [[ "$UNINSTALL_ALL" == true ]]; then
        run_all
    elif [[ -n "$MODULE" ]]; then
        run_module
    else
        run_interactive
    fi

    print_section "Uninstall Complete"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY-RUN: No changes were made"
    else
        echo "Some changes require logout/restart to take full effect."
    fi
}

main
