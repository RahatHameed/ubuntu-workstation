#!/bin/bash
# vpn-connect.sh - VPN connection wrapper with pluggable providers
#
# Usage:
#   ./vpn-connect.sh connect [country]
#   ./vpn-connect.sh disconnect
#   ./vpn-connect.sh status
#   ./vpn-connect.sh is-connected
#   ./vpn-connect.sh list-providers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDERS_DIR="$SCRIPT_DIR/providers"
CONFIG_FILE="$SCRIPT_DIR/../config.yaml"

# ============================================
# Config parsing
# ============================================

parse_yaml_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    local default="$4"

    [[ ! -f "$file" ]] && echo "$default" && return

    local value=$(sed -n "/^${section}:$/,/^[a-zA-Z_]/p" "$file" \
        | grep "^  ${key}:" \
        | head -1 \
        | sed "s/^  ${key}:[[:space:]]*//" \
        | tr -d '"' | tr -d "'")

    echo "${value:-$default}"
}

# ============================================
# Configuration (priority: env var > config.yaml > default)
# ============================================

load_config() {
    local config_provider=$(parse_yaml_value "$CONFIG_FILE" "vpn" "provider" "mullvad")
    local config_country=$(parse_yaml_value "$CONFIG_FILE" "vpn" "default_country" "de")

    VPN_PROVIDER="${VPN_PROVIDER:-$config_provider}"
    DEFAULT_COUNTRY="${DEFAULT_COUNTRY:-$config_country}"
}

load_config

# ============================================
# Provider loading
# ============================================

list_providers() {
    local providers=()
    for f in "$PROVIDERS_DIR"/*.sh; do
        [[ -f "$f" ]] || continue
        local name=$(basename "$f" .sh)
        [[ "$name" == _* ]] && continue  # Skip templates
        providers+=("$name")
    done
    printf '%s\n' "${providers[@]}"
}

load_provider() {
    local provider="$1"
    local provider_file="$PROVIDERS_DIR/${provider}.sh"

    if [[ ! -f "$provider_file" ]]; then
        echo "Error: Unknown provider '$provider'"
        echo "Available providers: $(list_providers | tr '\n' ' ')"
        echo "To add a new provider, copy $PROVIDERS_DIR/_template.sh"
        exit 1
    fi

    source "$provider_file"
}

# ============================================
# Connection helpers
# ============================================

vpn_wait_connected() {
    local timeout="${1:-10}"
    for ((i=1; i<=timeout; i++)); do
        if provider_is_connected; then
            echo "VPN connected ($(provider_name))"
            return 0
        fi
        sleep 1
    done
    echo "VPN connection timeout"
    return 1
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
VPN Connection Manager

Usage: $(basename "$0") <command> [options]

Commands:
  connect [country]   Connect to VPN (default: $DEFAULT_COUNTRY)
  disconnect          Disconnect from VPN
  status              Show connection status
  is-connected        Exit 0 if connected, 1 if not
  list-providers      List available VPN providers

Configuration (from config.yaml):
  VPN_PROVIDER=$VPN_PROVIDER
  DEFAULT_COUNTRY=$DEFAULT_COUNTRY

To change settings, edit config.yaml:
  vpn:
    provider: mullvad
    default_country: de

Or override via environment:
  VPN_PROVIDER=nordvpn ./vpn-connect.sh connect

Adding new providers:
  cp $PROVIDERS_DIR/_template.sh $PROVIDERS_DIR/myvpn.sh
  # Implement the required functions
EOF
}

main() {
    local command="${1:-}"

    # Handle list-providers before loading a provider
    if [[ "$command" == "list-providers" ]]; then
        echo "Available providers:"
        list_providers | while read -r p; do
            if [[ "$p" == "$VPN_PROVIDER" ]]; then
                echo "  $p (current)"
            else
                echo "  $p"
            fi
        done
        exit 0
    fi

    # Load the configured provider
    load_provider "$VPN_PROVIDER"

    case "$command" in
        connect)
            local country="${2:-$DEFAULT_COUNTRY}"
            provider_connect "$country"
            vpn_wait_connected
            ;;
        disconnect)
            provider_disconnect
            echo "VPN disconnected"
            ;;
        status)
            provider_status
            ;;
        is-connected)
            if provider_is_connected; then
                echo "Connected"
                exit 0
            else
                echo "Disconnected"
                exit 1
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
