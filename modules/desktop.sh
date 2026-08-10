#!/bin/bash
# desktop.sh - Desktop customization module (Plank, GNOME, themes)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Startup apps are their own module; desktop pulls it in so a full desktop
# install still ends up with the autostart entry.
source "$SCRIPT_DIR/startup.sh"

install_gnome_tools() {
    print_info "Installing GNOME tools..."
    apt_install gnome-tweaks
    apt_install gnome-shell-extensions
    apt_install chrome-gnome-shell
}

install_fonts() {
    print_info "Installing fonts..."
    apt_install fonts-inter
    apt_install fonts-roboto
}

install_plank() {
    apt_install plank

    # Create Plank config directory
    run mkdir -p "$HOME/.config/plank/dock1/launchers"

    # Create Plank autostart entry
    run mkdir -p "$HOME/.config/autostart"

    if [[ "$DRY_RUN" != true ]]; then
        cat > "$HOME/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Exec=bash -c "sleep 3 && GDK_BACKEND=x11 plank"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Dock
Comment=macOS-style dock
EOF
    else
        print_info "[DRY-RUN] Would create Plank autostart entry"
    fi

    print_status "Plank dock configured"
}

configure_gnome() {
    print_info "Configuring GNOME..."

    # Disable Ubuntu Dock (if using Plank)
    run gnome-extensions disable ubuntu-dock@ubuntu.com 2>/dev/null || true
    print_status "Ubuntu Dock disabled"

    # Font scaling
    run gsettings set org.gnome.desktop.interface text-scaling-factor 1.25
    print_status "Font scaling set to 1.25"
}

set_xorg_session() {
    print_info "Setting Xorg as default session..."

    local accounts_file="/var/lib/AccountsService/users/$USER"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would set Xorg as default session"
        return 0
    fi

    sudo tee "$accounts_file" > /dev/null << EOF
[User]
Session=ubuntu-xorg
XSession=ubuntu-xorg
EOF
    print_status "Xorg set as default session (required for Plank)"
}

install_whitesur_theme() {
    print_section "WhiteSur Theme (macOS-style)"

    if [[ -d "$HOME/.themes/WhiteSur-Dark" || -d "$HOME/.themes/WhiteSur-Light" ]]; then
        print_status "WhiteSur theme already installed"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would clone and install WhiteSur GTK theme"
        print_info "[DRY-RUN] Would clone and install WhiteSur icon theme"
        return 0
    fi

    # GTK Theme
    print_info "Installing WhiteSur GTK theme..."
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk-theme
    cd /tmp/WhiteSur-gtk-theme && ./install.sh
    rm -rf /tmp/WhiteSur-gtk-theme
    print_status "WhiteSur GTK theme installed"

    # Icon Theme
    print_info "Installing WhiteSur icon theme..."
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme
    cd /tmp/WhiteSur-icon-theme && ./install.sh
    rm -rf /tmp/WhiteSur-icon-theme
    print_status "WhiteSur icon theme installed"

    print_warning "Apply theme in GNOME Tweaks → Appearance"
}

install_desktop() {
    local config_file="${1:-}"
    local install_theme=false

    print_section "Desktop Customization"

    if [[ -n "$config_file" && -f "$config_file" ]]; then
        install_theme=$(parse_config "$config_file" "install_theme")
    fi

    install_gnome_tools
    install_fonts
    install_plank
    set_xorg_session
    configure_gnome
    install_startup

    if [[ "$install_theme" == "true" ]]; then
        install_whitesur_theme
    else
        print_warning "[MANUAL] Install WhiteSur theme:"
        echo "  git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
        echo "  cd WhiteSur-gtk-theme && ./install.sh"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_desktop "$1"
fi
