#!/bin/bash
# Docker cleanup script - kills orphaned docker-proxy processes and cleans up containers
# Run this after Docker Desktop starts to prevent port conflicts from zombie processes

LOG_FILE="/tmp/docker-cleanup.log"
KILLED_COUNT=0

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

log "Starting Docker cleanup..."

# Kill any orphaned docker-proxy processes (main cause of port conflicts)
# These processes are owned by root, so sudo is required
PROXY_PIDS=$(pgrep -f docker-proxy 2>/dev/null)
if [ -n "$PROXY_PIDS" ]; then
    KILLED_COUNT=$(echo "$PROXY_PIDS" | wc -l)
    log "Found orphaned docker-proxy processes: $PROXY_PIDS"
    sudo pkill -9 -f docker-proxy 2>/dev/null
    sleep 1
    # Verify they were killed
    REMAINING=$(pgrep -f docker-proxy 2>/dev/null)
    if [ -n "$REMAINING" ]; then
        log "WARNING: Some docker-proxy processes still running: $REMAINING"
    else
        log "Killed docker-proxy processes"
    fi
fi

# Wait for Docker daemon to be ready (max 30 seconds)
RETRIES=30
while [ $RETRIES -gt 0 ]; do
    if docker info &>/dev/null; then
        log "Docker daemon is ready"
        break
    fi
    sleep 1
    RETRIES=$((RETRIES - 1))
done

if [ $RETRIES -eq 0 ]; then
    log "Docker daemon not ready after 30s, skipping container cleanup"
    exit 1
fi

# Remove any stale containers
CONTAINERS=$(docker ps -aq 2>/dev/null)
if [ -n "$CONTAINERS" ]; then
    log "Removing stale containers..."
    docker rm -f $CONTAINERS 2>/dev/null
fi

# Prune orphan networks
docker network prune -f 2>/dev/null

log "Docker cleanup completed successfully"

# Print summary to terminal
if [ "$KILLED_COUNT" -gt 0 ]; then
    echo "Docker cleanup completed - killed $KILLED_COUNT orphaned docker-proxy processes"
else
    echo "Docker cleanup completed - no orphaned processes found"
fi
