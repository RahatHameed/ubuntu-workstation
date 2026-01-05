#!/bin/bash
# common.sh - Shared functions for all modules

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Globals
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}

# Print functions
print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_section() { echo -e "\n${GREEN}=== $1 ===${NC}\n"; }

# Dry run wrapper - executes command only if not in dry run mode
run() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would execute: $*"
        return 0
    else
        if [[ "$VERBOSE" == true ]]; then
            print_info "Executing: $*"
        fi
        "$@"
    fi
}

# Check if running on Ubuntu
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
        print_error "This script is designed for Ubuntu. Exiting."
        exit 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if a snap is installed
snap_installed() {
    snap list "$1" &>/dev/null
}

# Check if a dpkg package is installed
dpkg_installed() {
    dpkg -l "$1" &>/dev/null 2>&1
}

# Install apt package if not present
apt_install() {
    local package="$1"
    if ! dpkg_installed "$package"; then
        print_info "Installing $package..."
        run sudo apt install -y "$package"
        print_status "$package installed"
    else
        print_status "$package already installed"
    fi
}

# Install snap package if not present
snap_install() {
    local package="$1"
    local flags="${2:-}"
    if ! snap_installed "$package"; then
        print_info "Installing $package (snap)..."
        run sudo snap install "$package" $flags
        print_status "$package installed"
    else
        print_status "$package already installed"
    fi
}

# Download and install .deb file
deb_install() {
    local name="$1"
    local url="$2"
    local check_cmd="$3"

    if ! command_exists "$check_cmd"; then
        print_info "Installing $name..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would download: $url"
            print_info "[DRY-RUN] Would install .deb package"
        else
            wget -q --show-progress -O "/tmp/${name}.deb" "$url"
            sudo apt install -y "/tmp/${name}.deb"
            rm "/tmp/${name}.deb"
        fi
        print_status "$name installed"
    else
        print_status "$name already installed"
    fi
}

# Prompt for confirmation (returns 0 for yes, 1 for no)
confirm() {
    local prompt="${1:-Continue?}"
    read -p "$prompt (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Parse simple YAML config (key: value format)
parse_config() {
    local config_file="$1"
    local key="$2"

    if [[ -f "$config_file" ]]; then
        grep "^${key}:" "$config_file" | sed "s/^${key}:[[:space:]]*//" | tr -d '"' | tr -d "'"
    fi
}

# Parse YAML list items (returns space-separated values)
parse_config_list() {
    local config_file="$1"
    local section="$2"

    if [[ -f "$config_file" ]]; then
        awk "/^${section}:$/,/^[a-z]/" "$config_file" | grep "^  - " | sed 's/^  - //' | tr '\n' ' '
    fi
}

# Check if item is in config list
config_has() {
    local config_file="$1"
    local section="$2"
    local item="$3"

    local items=$(parse_config_list "$config_file" "$section")
    [[ " $items " == *" $item "* ]]
}

# Parse nested YAML value (e.g., "vpn.provider" for vpn: provider: value)
# Usage: parse_yaml config.yaml "vpn.provider" "default_value"
parse_yaml() {
    local config_file="$1"
    local key_path="$2"
    local default="${3:-}"

    if [[ ! -f "$config_file" ]]; then
        echo "$default"
        return
    fi

    # Split key path (e.g., "vpn.provider" -> "vpn" and "provider")
    local section="${key_path%%.*}"
    local key="${key_path#*.}"

    # If no dot in path, use simple parse
    if [[ "$section" == "$key" ]]; then
        local value=$(parse_config "$config_file" "$key")
        echo "${value:-$default}"
        return
    fi

    # Parse nested value - find section, then find key within it
    # Extract from section start to next top-level key or EOF
    local value=$(sed -n "/^${section}:$/,/^[a-zA-Z_]/p" "$config_file" | grep "^  ${key}:" | head -1 | sed "s/^  ${key}:[[:space:]]*//" | tr -d '"' | tr -d "'")

    echo "${value:-$default}"
}
