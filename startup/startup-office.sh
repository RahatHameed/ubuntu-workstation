#!/bin/bash
# startup-office.sh
# Launches essential work applications on startup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Connect to VPN first (configure provider in vpn/vpn-connect.sh)
"$SCRIPT_DIR/../vpn/vpn-connect.sh" connect

# Kill orphaned docker-proxy processes BEFORE starting Docker Desktop
pkill -9 -f docker-proxy 2>/dev/null

phpstorm &
slack &
google-chrome &
/opt/google/chrome/google-chrome --profile-directory=Default --app-id=faolnafnngnfdaknnbpnkhgohbobgegn &  # Outlook PWA
GDK_BACKEND=x11 plank &
/opt/docker-desktop/bin/docker-desktop &
gnome-terminal &

# Run Docker cleanup in background after Docker Desktop has time to start
(sleep 15 && "$SCRIPT_DIR/../docker/docker-cleanup.sh") &
