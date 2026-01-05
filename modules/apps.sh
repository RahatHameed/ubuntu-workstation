#!/bin/bash
# apps.sh - Work applications installation module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Individual app installers
install_chrome() {
    deb_install "google-chrome" \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
        "google-chrome"
}

install_slack() {
    snap_install "slack" "--classic"
}

install_teams() {
    snap_install "teams-for-linux"
}

install_jetbrains_toolbox() {
    if ! command_exists jetbrains-toolbox && [[ ! -d "$HOME/.local/share/JetBrains/Toolbox" ]]; then
        print_info "Installing JetBrains Toolbox..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would download and install JetBrains Toolbox"
        else
            local toolbox_url
            toolbox_url=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | grep -Po '"linux":{"link":"\K[^"]+')
            wget -q --show-progress -O /tmp/jetbrains-toolbox.tar.gz "$toolbox_url"
            tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp
            /tmp/jetbrains-toolbox-*/jetbrains-toolbox &
            rm -rf /tmp/jetbrains-toolbox*
        fi
        print_status "JetBrains Toolbox installed (use it to install IDEs)"
    else
        print_status "JetBrains Toolbox already installed"
    fi
}

install_vscode() {
    if ! command_exists code; then
        print_info "Installing VS Code..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would install VS Code via snap"
        else
            snap_install "code" "--classic"
        fi
    else
        print_status "VS Code already installed"
    fi
}

install_spotify() {
    snap_install "spotify"
}

install_discord() {
    snap_install "discord"
}

install_zoom() {
    deb_install "zoom" \
        "https://zoom.us/client/latest/zoom_amd64.deb" \
        "zoom"
}

install_postman() {
    snap_install "postman"
}

install_dbeaver() {
    snap_install "dbeaver-ce"
}

install_tigervnc() {
    apt_install "tigervnc-standalone-server"
    apt_install "tigervnc-viewer"
    print_warning "Run 'vncpasswd' to set VNC password"
    print_warning "Run 'vncserver :1' to start VNC server"
}

# Main function - installs based on config or all by default
install_apps() {
    local config_file="${1:-}"

    print_section "Installing Work Applications"

    if [[ -n "$config_file" && -f "$config_file" ]]; then
        # Install only apps specified in config
        config_has "$config_file" "apps" "chrome" && install_chrome
        config_has "$config_file" "apps" "slack" && install_slack
        config_has "$config_file" "apps" "teams" && install_teams
        config_has "$config_file" "apps" "jetbrains-toolbox" && install_jetbrains_toolbox
        config_has "$config_file" "apps" "vscode" && install_vscode
        config_has "$config_file" "apps" "discord" && install_discord
        config_has "$config_file" "apps" "zoom" && install_zoom
        config_has "$config_file" "apps" "postman" && install_postman
        # Optional apps (not installed by default)
        config_has "$config_file" "apps" "spotify" && install_spotify
        config_has "$config_file" "apps" "dbeaver" && install_dbeaver
        config_has "$config_file" "apps" "tigervnc" && install_tigervnc
    else
        # Default: install core work apps only
        install_chrome
        install_slack
        install_teams
        install_jetbrains_toolbox
    fi
}

# Interactive selection
install_apps_interactive() {
    print_section "Select Applications to Install"

    local apps=()

    confirm "Install Google Chrome?" && apps+=("chrome")
    confirm "Install Slack?" && apps+=("slack")
    confirm "Install Microsoft Teams?" && apps+=("teams")
    confirm "Install JetBrains Toolbox?" && apps+=("jetbrains-toolbox")
    confirm "Install VS Code?" && apps+=("vscode")
    confirm "Install Spotify?" && apps+=("spotify")
    confirm "Install Discord?" && apps+=("discord")
    confirm "Install Zoom?" && apps+=("zoom")
    confirm "Install Postman?" && apps+=("postman")
    confirm "Install DBeaver?" && apps+=("dbeaver")
    confirm "Install TigerVNC?" && apps+=("tigervnc")

    echo ""
    for app in "${apps[@]}"; do
        case "$app" in
            chrome) install_chrome ;;
            slack) install_slack ;;
            teams) install_teams ;;
            jetbrains-toolbox) install_jetbrains_toolbox ;;
            vscode) install_vscode ;;
            spotify) install_spotify ;;
            discord) install_discord ;;
            zoom) install_zoom ;;
            postman) install_postman ;;
            dbeaver) install_dbeaver ;;
            tigervnc) install_tigervnc ;;
        esac
    done
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$1" == "-i" || "$1" == "--interactive" ]]; then
        install_apps_interactive
    else
        install_apps "$1"
    fi
fi
