#!/bin/bash
# mullvad.sh - Mullvad VPN provider

provider_name() {
    echo "Mullvad VPN"
}

provider_check_installed() {
    command -v mullvad &>/dev/null
}

# ============================================
# Installation
# ============================================

provider_install() {
    if provider_check_installed; then
        print_status "Mullvad VPN already installed"
        return 0
    fi

    print_info "Installing Mullvad VPN..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install Mullvad VPN"
        return 0
    fi

    apt_install curl

    # Download and add signing key
    run sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc \
        https://repository.mullvad.net/deb/mullvad-keyring.asc

    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$(dpkg --print-architecture)] https://repository.mullvad.net/deb/stable stable main" \
        | sudo tee /etc/apt/sources.list.d/mullvad.list > /dev/null

    run sudo apt update
    apt_install mullvad-vpn

    print_status "Mullvad VPN installed"
}

provider_configure() {
    local account_number="${VPN_ACCOUNT_NUMBER:-}"

    if [[ -n "$account_number" ]]; then
        print_info "Logging into Mullvad..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would login with account number"
        else
            mullvad account login "$account_number"
            print_status "Mullvad account configured"
        fi
    else
        print_warning "Run 'mullvad account login YOUR_ACCOUNT_NUMBER' to authenticate"
    fi
}

# ============================================
# Connection management
# ============================================

provider_connect() {
    local country="${1:-}"
    if [[ -n "$country" ]]; then
        mullvad relay set location "$country"
    fi
    mullvad connect
}

provider_disconnect() {
    mullvad disconnect
}

provider_status() {
    mullvad status
}

provider_is_connected() {
    mullvad status | grep -q "Connected"
}
