#!/bin/bash
# startup-office.sh
# Launches essential work applications on startup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Apply IPv6 config (disabled by default to prevent VPN leaks)
"$SCRIPT_DIR/../vpn/ipv6-disable.sh" || echo "Warning: IPv6 config failed. Continuing anyway..."

# Try to connect VPN if auto_connect=true in config
"$SCRIPT_DIR/../vpn/vpn-connect.sh" auto-connect || echo "Warning: VPN auto-connect failed. Continuing anyway..."

# Kill orphaned docker-proxy processes BEFORE starting Docker Desktop
pkill -9 -f docker-proxy 2>/dev/null

phpstorm &
slack &
teams-for-linux &
google-chrome &
/opt/google/chrome/google-chrome --profile-directory=Default --app-id=faolnafnngnfdaknnbpnkhgohbobgegn &  # Outlook PWA
GDK_BACKEND=x11 plank &
/opt/docker-desktop/bin/docker-desktop &
gnome-terminal &

# Run Docker cleanup in background after Docker Desktop has time to start
(sleep 15 && "$SCRIPT_DIR/../docker/docker-cleanup.sh") &
