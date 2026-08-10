#!/bin/bash
# startup.sh - Startup applications module (autostart entry for startup-office.sh)
#
# Standalone on purpose: the autostart entry is the only thing needed to launch
# work apps on login, so it must not drag in Plank, the Xorg switch, or the
# GNOME tweaks that live in desktop.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_ENTRY="$AUTOSTART_DIR/startup-office.desktop"

install_startup() {
    print_section "Startup Applications"

    local startup_script="$(cd "$SCRIPT_DIR/.." && pwd)/startup/startup-office.sh"

    if [[ ! -f "$startup_script" ]]; then
        print_error "startup-office.sh not found at $startup_script"
        return 1
    fi

    # An autostart entry pointing at a non-executable script fails silently at
    # login, so make sure the bit is set rather than assuming the clone kept it.
    if [[ ! -x "$startup_script" ]]; then
        print_info "Making startup-office.sh executable..."
        run chmod +x "$startup_script"
    fi

    run mkdir -p "$AUTOSTART_DIR"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would create $AUTOSTART_ENTRY"
        print_info "[DRY-RUN]   Exec=$startup_script"
        return 0
    fi

    cat > "$AUTOSTART_ENTRY" << EOF
[Desktop Entry]
Type=Application
Exec=$startup_script
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Work Apps
Comment=Launch work applications on startup
EOF

    print_status "Autostart entry created: $AUTOSTART_ENTRY"
    print_info "Launches: $startup_script"
    print_warning "The path above is baked into the entry - re-run this module if you move the repo"
    print_info "Takes effect at your next login"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_startup
fi
