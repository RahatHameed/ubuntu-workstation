#!/bin/bash
# nordvpn.sh - NordVPN provider

provider_name() {
    echo "NordVPN"
}

provider_check_installed() {
    command -v nordvpn &>/dev/null
}

# ============================================
# Installation
# ============================================

provider_install() {
    if provider_check_installed; then
        print_status "NordVPN already installed"
        return 0
    fi

    print_info "Installing NordVPN..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install NordVPN"
        return 0
    fi

    # Install via official script
    sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)

    print_status "NordVPN installed"
}

provider_configure() {
    print_warning "Run 'nordvpn login' to authenticate (opens browser)"
}

# ============================================
# Connection management
# ============================================

provider_connect() {
    local country="${1:-}"
    if [[ -n "$country" ]]; then
        nordvpn connect "$country"
    else
        nordvpn connect
    fi
}

provider_disconnect() {
    nordvpn disconnect
}

provider_status() {
    nordvpn status
}

provider_is_connected() {
    nordvpn status | grep -q "Connected"
}
