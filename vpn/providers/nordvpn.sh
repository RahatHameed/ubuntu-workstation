#!/bin/bash
# nordvpn.sh - NordVPN provider

provider_name() {
    echo "NordVPN"
}

provider_check_installed() {
    command -v nordvpn &>/dev/null
}

# ============================================
# IPv6 Leak Protection
# ============================================

disable_ipv6() {
    echo "Disabling IPv6 to prevent leaks..."
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
}

enable_ipv6() {
    echo "Re-enabling IPv6..."
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null 2>&1
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
    local city="${2:-}"

    # Block IPv6 before connecting to prevent leaks
    disable_ipv6

    if [[ -n "$country" && -n "$city" ]]; then
        # Connect to specific city (e.g., "Germany Frankfurt")
        nordvpn connect "$country" "$city"
    elif [[ -n "$country" ]]; then
        nordvpn connect "$country"
    else
        nordvpn connect
    fi
}

provider_disconnect() {
    nordvpn disconnect
    # Re-enable IPv6 after disconnecting
    enable_ipv6
}

provider_status() {
    nordvpn status
}

provider_is_connected() {
    nordvpn status | grep -q "Connected"
}
