#!/bin/bash
# Docker cleanup script - kills orphaned docker-proxy processes and cleans up containers
# Run this after Docker Desktop starts to prevent port conflicts from zombie processes

LOG_FILE="/tmp/docker-cleanup.log"
KILLED_COUNT=0
ALL_ORPHANS=false

for ARG in "$@"; do
    case "$ARG" in
        --all-orphans) ALL_ORPHANS=true ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--all-orphans]"
            echo
            echo "  Kills orphaned docker-proxy processes, removes stopped containers,"
            echo "  removes containers whose image no longer exists, prunes unused networks."
            echo
            echo "  --all-orphans  also remove containers still running on an image tag"
            echo "                 that has since been rebuilt"
            exit 0
            ;;
        *) echo "Unknown option: $ARG" >&2; exit 1 ;;
    esac
done

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

# Remove stopped containers only - running and paused ones are left alone
STOPPED=$(docker ps -aq -f status=exited -f status=created -f status=dead 2>/dev/null)
if [ -n "$STOPPED" ]; then
    log "Removing stopped containers: $(echo "$STOPPED" | tr '\n' ' ')"
    docker rm $STOPPED 2>/dev/null
else
    log "No stopped containers to remove"
fi

# Remove orphaned containers - ones whose image ID is gone from the local
# store, so they can never be restarted or rebuilt from what they run on.
#
# A running container whose image *tag* still resolves is not truly parentless:
# it is the normal result of rebuilding a tag while the old container keeps
# running the previous layers, and `docker compose up` recreates it. Those are
# only reported, unless --all-orphans is given.
ORPHANS=""
REBUILT=""
for CONTAINER in $(docker ps -aq 2>/dev/null); do
    IMAGE=$(docker inspect -f '{{.Image}}' "$CONTAINER" 2>/dev/null)
    [ -n "$IMAGE" ] || continue
    docker image inspect "$IMAGE" &>/dev/null && continue

    NAME=$(docker inspect -f '{{.Name}}' "$CONTAINER" 2>/dev/null | sed 's|^/||')
    TAG=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER" 2>/dev/null)
    if [ "$ALL_ORPHANS" != true ] && [ -n "$TAG" ] && docker image inspect "$TAG" &>/dev/null; then
        REBUILT="$REBUILT $NAME"
    else
        ORPHANS="$ORPHANS $CONTAINER"
        log "Orphan: $NAME (image $IMAGE no longer exists)"
    fi
done

if [ -n "$ORPHANS" ]; then
    log "Removing orphaned containers:$ORPHANS"
    docker rm -f $ORPHANS 2>/dev/null
else
    log "No orphaned containers to remove"
fi

if [ -n "$REBUILT" ]; then
    log "Left running on a rebuilt image tag:$REBUILT (--all-orphans removes these too)"
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
