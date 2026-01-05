#!/bin/bash
# _template.sh - Template for adding new VPN providers
#
# To add a new provider:
# 1. Copy this file: cp _template.sh myvpn.sh
# 2. Implement all functions below
# 3. Test: ./vpn-connect.sh status (after setting VPN_PROVIDER=myvpn)
#
# The provider filename (without .sh) becomes the provider name.
# Example: expressvpn.sh -> VPN_PROVIDER=expressvpn

# ============================================
# Required: Installation (used by modules/vpn.sh)
# ============================================

provider_install() {
    # Install the VPN client
    # Use apt_install, snap_install, or manual installation
    # Example:
    #   apt_install myvpn-client
    echo "TODO: Implement installation"
}

provider_configure() {
    # Post-installation configuration
    # Handle account setup, initial config, etc.
    # Example:
    #   print_warning "Run 'myvpn login' to authenticate"
    echo "TODO: Implement configuration"
}

# ============================================
# Required: Connection management (used by vpn-connect.sh)
# ============================================

provider_connect() {
    local country="${1:-}"
    # Connect to VPN, optionally to specific country
    # Example:
    #   myvpn connect "$country"
    echo "TODO: Implement connect"
}

provider_disconnect() {
    # Disconnect from VPN
    # Example:
    #   myvpn disconnect
    echo "TODO: Implement disconnect"
}

provider_status() {
    # Print human-readable status
    # Example:
    #   myvpn status
    echo "TODO: Implement status"
}

provider_is_connected() {
    # Return 0 if connected, 1 if not (for scripting)
    # Example:
    #   myvpn status | grep -q "Connected"
    return 1
}

# ============================================
# Optional: Provider metadata
# ============================================

provider_name() {
    echo "MyVPN"  # Human-readable name
}

provider_check_installed() {
    # Return 0 if VPN client is installed
    # Example:
    #   command -v myvpn &>/dev/null
    return 1
}
