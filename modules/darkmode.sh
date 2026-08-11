#!/bin/bash
# darkmode.sh - Follow the sun: dark GNOME colour scheme at sunset, light at sunrise
#
# Separate from desktop.sh on purpose. desktop.sh installs a GTK theme and tweaks
# Plank and fonts; this only automates the light/dark switch, and someone may
# well want one without the other.
#
# GNOME has no built-in day/night switching. Night Light is a different feature:
# it warms the screen's colour temperature and leaves the theme alone. A systemd
# user timer is used rather than a shell extension, so it needs no logout to take
# effect and does not break on a GNOME upgrade.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

BIN_DIR="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"

install_darkmode() {
    local config_file="${1:-}"
    print_section "Dark Mode at Sunset"

    local script="$(cd "$SCRIPT_DIR/.." && pwd)/utils/dark-at-sunset"

    if [[ ! -f "$script" ]]; then
        print_error "dark-at-sunset not found at $script"
        return 1
    fi

    if ! command_exists gsettings; then
        print_warning "gsettings not found; this needs a GNOME session. Skipping."
        return 0
    fi

    # Coordinates default to the system timezone's, from tzdata. Override in the
    # config when the timezone's reference city is far from where you actually
    # are -- sunset in Freiburg differs from Berlin by about 20 minutes.
    local lat="" lon=""
    if [[ -n "$config_file" && -f "$config_file" ]]; then
        lat=$(parse_config "$config_file" "darkmode_latitude" 2>/dev/null || true)
        lon=$(parse_config "$config_file" "darkmode_longitude" 2>/dev/null || true)
    fi

    local args=""
    if [[ -n "$lat" && -n "$lon" ]]; then
        args=" --lat $lat --lon $lon"
        print_info "Using configured coordinates: $lat, $lon"
    else
        print_info "Using coordinates from the system timezone"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install $BIN_DIR/dark-at-sunset"
        print_info "[DRY-RUN] Would write $UNIT_DIR/dark-at-sunset.{service,timer}"
        print_info "[DRY-RUN] Would enable dark-at-sunset.timer (checks every 15 min)"
        return 0
    fi

    run mkdir -p "$BIN_DIR" "$UNIT_DIR"
    run install -m 755 "$script" "$BIN_DIR/dark-at-sunset"

    cat > "$UNIT_DIR/dark-at-sunset.service" << EOF
[Unit]
Description=Set the GNOME colour scheme from the sun's position

[Service]
Type=oneshot
ExecStart=%h/.local/bin/dark-at-sunset apply${args}
EOF

    cat > "$UNIT_DIR/dark-at-sunset.timer" << 'EOF'
[Unit]
Description=Check whether the GNOME colour scheme should follow the sun

[Timer]
# Poll rather than scheduling the exact transition: polling survives suspend,
# resume, travelling across timezones and the clocks changing, and holds no
# state that could go stale.
OnStartupSec=30s
OnUnitActiveSec=15min
Persistent=true
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

    run systemctl --user daemon-reload
    run systemctl --user enable --now dark-at-sunset.timer

    print_status "Dark mode will follow the sun"
    "$BIN_DIR/dark-at-sunset" status | sed 's/^/    /'
    print_info "Force it either way with: dark-at-sunset dark|light"
    print_info "Disable with: systemctl --user disable --now dark-at-sunset.timer"
}
