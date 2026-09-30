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

# Slack as a Chrome web app rather than the snap. The snap is a whole second
# Electron runtime for a client that is already a web app, and it is slower to
# start and to update than the tab it wraps. Chrome is a dependency either way.
#
# Two kinds of Chrome web app can end up in the menu, and they do not behave the
# same. A Chrome-registered PWA ("Install page as app" from Chrome's own UI) has
# an app id, and launching that id returns to the window that is already open. A
# --app=URL launcher has no app identity at all, so Chrome has nothing to match
# against and every click opens another Slack window.
#
# Registering a PWA cannot be driven from the command line, so the --app
# launcher stays as the fallback for a fresh machine. Once the real app is
# installed the fallback is a duplicate that reopens the window-per-click
# problem, so it gets cleared out.
SLACK_URL="https://app.slack.com/client"
SLACK_ICON_URL="https://a.slack-edge.com/80588/marketing/img/meta/slack_hash_256.png"

# Print the launcher Chrome wrote for a registered Slack PWA, if there is one.
# Chrome names those chrome-<app id>-Default.desktop and gives them --app-id;
# the visible name comes from the site, so it is "<Workspace> - Slack" rather
# than anything we could predict.
chrome_slack_app() {
    local desktop
    for desktop in "$HOME/.local/share/applications"/chrome-*-Default.desktop; do
        [[ -f "$desktop" ]] || continue
        grep -q '^Exec=.*--app-id=' "$desktop" || continue
        grep -qi '^Name=.*slack' "$desktop" || continue
        echo "$desktop"
        return 0
    done
    return 1
}

install_slack() {
    if ! command_exists google-chrome; then
        print_warning "Slack as a web app needs Google Chrome; install that first. Skipping."
        return 0
    fi

    local desktop="$HOME/.local/share/applications/slack-pwa.desktop"
    local icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"

    local registered
    if registered=$(chrome_slack_app); then
        print_status "Slack is already installed as a Chrome app ($(basename "$registered"))"
        if [[ -f "$desktop" ]]; then
            print_info "Removing the older --app launcher; it opened a second window per click"
            run rm -f "$desktop" "$icon_dir/slack-pwa.png"
            run update-desktop-database "$HOME/.local/share/applications"
        fi
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would write $desktop"
        print_info "[DRY-RUN] Would fetch the Slack icon into $icon_dir"
        return 0
    fi

    run mkdir -p "$(dirname "$desktop")" "$icon_dir"

    # A missing icon is not worth failing over: the launcher works without one,
    # it just inherits Chrome's. Same treatment as JetBrains Toolbox above.
    local icon="slack-pwa"
    if [[ -f "$icon_dir/slack-pwa.png" ]]; then
        :
    elif curl -fsSL --max-time 30 -o "$icon_dir/slack-pwa.png" "$SLACK_ICON_URL"; then
        chmod 644 "$icon_dir/slack-pwa.png"
    else
        rm -f "$icon_dir/slack-pwa.png"
        icon="google-chrome"
        print_warning "Could not fetch the Slack icon; the launcher will use Chrome's"
    fi

    # GTK trusts icon-theme.cache over the directory whenever one exists, so a
    # cache older than the icon hides a file that is sitting right there. Refresh
    # one if the tree has it, but never create one: without a cache the icon
    # loader just scans the directory, which cannot go stale.
    local icon_root="$HOME/.local/share/icons/hicolor"
    if [[ -f "$icon_root/icon-theme.cache" ]] && command_exists gtk-update-icon-cache; then
        run gtk-update-icon-cache -q -t "$icon_root"
    fi

    # No MimeType line on purpose. Claiming x-scheme-handler/slack would take
    # slack:// links away from the desktop app for anyone who still has it, and
    # this launcher cannot do anything useful with one.
    #
    # StartupWMClass is the class Chrome derives from the URL for --app windows.
    # Without it the window lands under a generic Chrome icon in the dock rather
    # than under this launcher.
    cat > "$desktop" << EOF
[Desktop Entry]
Version=1.0
Terminal=false
Type=Application
Name=Slack (PWA)
GenericName=Slack Client for Linux
Comment=Slack in a standalone Chrome window
Categories=Network;InstantMessaging;
Exec=/opt/google/chrome/google-chrome --profile-directory=Default --app=$SLACK_URL
Icon=$icon
StartupNotify=true
StartupWMClass=app.slack.com__client
EOF
    run chmod 644 "$desktop"
    run update-desktop-database "$HOME/.local/share/applications"
    print_status "Slack installed as a Chrome web app"
    print_info "Clicking this launcher opens a new window every time. For one window"
    print_info "that comes back to the front, open $SLACK_URL in Chrome and use the"
    print_info "address bar's install button (or ⋮ > Cast, save and share > Install"
    print_info "page as app); re-running this module then drops the launcher."

    if snap_installed "slack"; then
        print_warning "The Slack snap is still installed: sudo snap remove slack"
    fi
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
