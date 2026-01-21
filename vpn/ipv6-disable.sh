#!/bin/bash
# ipv6-disable.sh - Disable IPv6 to prevent VPN leaks
#
# Usage:
#   ./ipv6-disable.sh         # Apply config (disable if ipv6_disable: true)
#   ./ipv6-disable.sh disable # Force disable IPv6
#   ./ipv6-disable.sh enable  # Force enable IPv6
#   ./ipv6-disable.sh status  # Check current IPv6 status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.yaml"

# ============================================
# Config parsing (same as vpn-connect.sh)
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

# Load config (default: IPv6 disabled for VPN leak protection)
load_config() {
    local config_value=$(parse_yaml_value "$CONFIG_FILE" "vpn" "ipv6_disable" "true")
    IPV6_DISABLE="${IPV6_DISABLE:-$config_value}"
}

load_config

# ============================================
# Functions
# ============================================

check_ipv6_status() {
    local all_disabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo "0")
    local default_disabled=$(cat /proc/sys/net/ipv6/conf/default/disable_ipv6 2>/dev/null || echo "0")

    if [[ "$all_disabled" == "1" && "$default_disabled" == "1" ]]; then
        echo "disabled"
    else
        echo "enabled"
    fi
}

disable_ipv6() {
    echo "Disabling IPv6..."

    # Disable globally
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
    sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1 >/dev/null

    # Disable on each active interface and flush existing addresses
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | cut -d'@' -f1); do
        sudo sysctl -w "net.ipv6.conf.${iface}.disable_ipv6=1" >/dev/null 2>&1 || true
        sudo ip -6 addr flush dev "$iface" scope global 2>/dev/null || true
    done

    echo "IPv6 disabled and addresses flushed (temporary, until reboot)"
}

enable_ipv6() {
    echo "Enabling IPv6..."
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
    echo "IPv6 enabled"
}

SYSCTL_CONF="/etc/sysctl.d/99-disable-ipv6.conf"

persist_config() {
    if [[ "$IPV6_DISABLE" == "true" ]]; then
        echo "Creating persistent IPv6 disable config..."
        printf '%s\n' \
            '# Disable IPv6 to prevent VPN leaks' \
            'net.ipv6.conf.all.disable_ipv6=1' \
            'net.ipv6.conf.default.disable_ipv6=1' \
            'net.ipv6.conf.lo.disable_ipv6=1' \
            | sudo tee "$SYSCTL_CONF" >/dev/null
        echo "Created $SYSCTL_CONF - IPv6 will stay disabled after reboot"
    else
        if [[ -f "$SYSCTL_CONF" ]]; then
            echo "Removing persistent IPv6 disable config..."
            sudo rm "$SYSCTL_CONF"
            echo "Removed $SYSCTL_CONF - IPv6 will be enabled after reboot"
        else
            echo "Config ipv6_disable is false, no persistent config to create"
        fi
    fi
}

apply_config() {
    local current_status=$(check_ipv6_status)

    if [[ "$IPV6_DISABLE" == "true" ]]; then
        if [[ "$current_status" == "enabled" ]]; then
            disable_ipv6
        else
            echo "IPv6 already disabled"
        fi
    else
        if [[ "$current_status" == "disabled" ]]; then
            enable_ipv6
        else
            echo "IPv6 already enabled"
        fi
    fi
}

show_status() {
    local status=$(check_ipv6_status)
    echo "IPv6 status: $status"
    echo "Config (ipv6_disable): $IPV6_DISABLE"

    # Check for any remaining global IPv6 addresses (leak check)
    local ipv6_addrs
    ipv6_addrs=$(ip -6 addr show scope global 2>/dev/null | grep -c "inet6" 2>/dev/null) || ipv6_addrs=0
    if [[ "$ipv6_addrs" -gt 0 ]]; then
        echo "WARNING: $ipv6_addrs global IPv6 address(es) still assigned!"
        ip -6 addr show scope global 2>/dev/null | grep "inet6" | awk '{print "  " $2}'
    else
        echo "No global IPv6 addresses (good)"
    fi

    # Always test external IPv6 connectivity (leak test)
    local ipv6=$(curl -6 -s --max-time 3 ifconfig.me 2>/dev/null || echo "blocked")
    if [[ "$ipv6" == "blocked" ]]; then
        echo "External IPv6: blocked (no leak)"
    else
        echo "WARNING: External IPv6 LEAKING: $ipv6"
    fi

    # Show IPv4
    local ipv4=$(curl -4 -s --max-time 3 ifconfig.me 2>/dev/null || echo "not reachable")
    echo "External IPv4: $ipv4"
}

show_help() {
    cat <<EOF
IPv6 Disable Script - Prevent VPN IPv6 leaks

Usage: $(basename "$0") [command]

Commands:
  (no args)   Apply config setting (ipv6_disable: $IPV6_DISABLE)
  disable     Force disable IPv6
  enable      Force enable IPv6
  persist     Make config persistent (survives reboot)
  status      Check current IPv6 status and external IPs
  help        Show this help

Configuration (config.yaml):
  vpn:
    ipv6_disable: true    # true = disable IPv6, false = enable

Override via environment:
  IPV6_DISABLE=false $(basename "$0")

Note: Changes are temporary unless you run 'persist'.
      Use 'persist' to make settings survive reboot.
EOF
}

# ============================================
# Main
# ============================================

main() {
    local command="${1:-}"

    case "$command" in
        disable)
            disable_ipv6
            show_status
            ;;
        enable)
            enable_ipv6
            show_status
            ;;
        persist)
            persist_config
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            # No args: apply config
            apply_config
            ;;
        *)
            echo "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
