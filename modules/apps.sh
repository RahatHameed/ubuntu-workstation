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
    if command_exists jetbrains-toolbox || [[ -d "$HOME/.local/share/JetBrains/Toolbox" ]]; then
        print_status "JetBrains Toolbox already installed"
        return 0
    fi

    print_info "Installing JetBrains Toolbox..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would download and install JetBrains Toolbox"
        return 0
    fi

    # Every failure below is non-fatal: the installer runs under `set -e`, so a
    # bad response from the JetBrains API must not abort the whole run.
    local toolbox_url=""
    toolbox_url=$(curl -fsSL --max-time 30 \
        "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" \
        2>/dev/null | grep -Po '"linux":\{"link":"\K[^"]+' | head -1) || true

    if [[ -z "$toolbox_url" ]]; then
        print_warning "Could not determine JetBrains Toolbox download URL"
        print_warning "[MANUAL] Install from https://www.jetbrains.com/toolbox-app/"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    if ! wget -q --show-progress -O "$tmp_dir/jetbrains-toolbox.tar.gz" "$toolbox_url"; then
        print_warning "JetBrains Toolbox download failed: $toolbox_url"
        rm -rf "$tmp_dir"
        return 0
    fi

    if ! tar -xzf "$tmp_dir/jetbrains-toolbox.tar.gz" -C "$tmp_dir"; then
        print_warning "Could not extract JetBrains Toolbox archive"
        rm -rf "$tmp_dir"
        return 0
    fi

    # Archive layout differs between releases (./jetbrains-toolbox vs ./bin/jetbrains-toolbox)
    local binary
    binary=$(find "$tmp_dir" -type f -name jetbrains-toolbox -perm -u+x | head -1)

    if [[ -z "$binary" ]]; then
        print_warning "jetbrains-toolbox binary not found in archive"
        rm -rf "$tmp_dir"
        return 0
    fi

    mkdir -p "$HOME/.local/bin"

    if [[ "$(basename "$(dirname "$binary")")" == "bin" ]]; then
        # Toolbox 2.x+ ships a ~220MB app tree: the launcher loads bin/lib/*.jar and
        # its sibling .so files by relative path. Copying the launcher alone leaves it
        # orphaned - it then exits 53 with no output at all. Install the whole tree.
        local app_dir="$HOME/.local/opt/jetbrains-toolbox"
        mkdir -p "$HOME/.local/opt"
        rm -rf "$app_dir"

        if ! mv "$(dirname "$(dirname "$binary")")" "$app_dir"; then
            print_warning "Could not install JetBrains Toolbox to $app_dir"
            rm -rf "$tmp_dir"
            return 0
        fi

        ln -sfn "$app_dir/bin/jetbrains-toolbox" "$HOME/.local/bin/jetbrains-toolbox"
        print_status "JetBrains Toolbox installed to ~/.local/opt/jetbrains-toolbox"
    else
        # Older releases are a single self-contained AppImage - the binary is enough
        cp "$binary" "$HOME/.local/bin/jetbrains-toolbox"
        chmod +x "$HOME/.local/bin/jetbrains-toolbox"
        print_status "JetBrains Toolbox installed to ~/.local/bin/jetbrains-toolbox"
    fi

    rm -rf "$tmp_dir"

    print_warning "Run 'jetbrains-toolbox' to finish setup and install IDEs"
    print_warning "Then enable Toolbox shell scripts so 'phpstorm' resolves on PATH"
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

# make, gcc, g++, libc headers - needed to build anything from source
install_build_tools() {
    apt_install "build-essential"
}

install_gh() {
    apt_install "gh"
    print_warning "Run 'gh auth login' to authenticate (also wires up git credentials)"
}

# Main function - installs based on config or all by default
install_apps() {
    local config_file="${1:-}"

    print_section "Installing Work Applications"

    if [[ -n "$config_file" && -f "$config_file" ]]; then
        # Install only apps specified in config
        config_has "$config_file" "apps" "build-tools" && install_build_tools
        config_has "$config_file" "apps" "gh" && install_gh
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

    confirm "Install build tools (make, gcc, g++)?" && apps+=("build-tools")
    confirm "Install GitHub CLI (gh)?" && apps+=("gh")
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
            build-tools) install_build_tools ;;
            gh) install_gh ;;
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
