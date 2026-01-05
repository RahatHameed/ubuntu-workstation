#!/bin/bash
# protonvpn.sh - ProtonVPN provider

provider_name() {
    echo "ProtonVPN"
}

provider_check_installed() {
    command -v protonvpn-cli &>/dev/null
}

# ============================================
# Installation
# ============================================

provider_install() {
    if provider_check_installed; then
        print_status "ProtonVPN already installed"
        return 0
    fi

    print_info "Installing ProtonVPN..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install ProtonVPN"
        return 0
    fi

    # Download and install ProtonVPN repo
    local deb_url="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.6_all.deb"
    wget -q -O /tmp/protonvpn-release.deb "$deb_url"
    run sudo dpkg -i /tmp/protonvpn-release.deb
    run sudo apt update
    apt_install protonvpn-gnome-desktop

    print_status "ProtonVPN installed"
}

provider_configure() {
    print_warning "Run 'protonvpn-cli login' to authenticate"
}

# ============================================
# Connection management
# ============================================

provider_connect() {
    local country="${1:-}"
    if [[ -n "$country" ]]; then
        protonvpn-cli connect --cc "$country"
    else
        protonvpn-cli connect --fastest
    fi
}

provider_disconnect() {
    protonvpn-cli disconnect
}

provider_status() {
    protonvpn-cli status
}

provider_is_connected() {
    protonvpn-cli status | grep -q "Connected"
}
