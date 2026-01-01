#!/bin/bash
set -eou pipefail

# Healthcheck script for CS2 Docker
# Performs a real A2S_INFO query to ensure the Source 2 engine is responding

PORT=${CS2_PORT:-27015}
TIMEOUT=5

# Import central logging & notification service
source /home/steam/notifications.sh

# Check if we are currently in the SteamCMD update/install phase
# During this phase, the server is NOT expected to respond to A2S_INFO.
if pgrep -x "steamcmd" > /dev/null || pgrep -f "steamcmd.sh" > /dev/null || pgrep -f "linux64/steamcmd" > /dev/null; then
    exit 0
fi

# If the CS2 process isn't even running yet, it's still initializing.
if ! pgrep -x "cs2" > /dev/null && ! pgrep -f "cs2/game/bin/linux64/cs2" > /dev/null; then
    exit 0
fi

# A2S_INFO Request
QUERY=$(printf "\xff\xff\xff\xffTSource Engine Query\0")

# Check if server responds to A2S_INFO
RESPONSE=$(echo -ne "$QUERY" | nc -u -w "$TIMEOUT" 127.0.0.1 "$PORT" | head -c 5 | od -An -t x1 | tr -d ' ' || true)

READY_FLAG="/tmp/server_ready"

if [[ "$RESPONSE" == "ffffffff49" ]]; then
    # Mark server as officially "ready" for the first time
    touch "$READY_FLAG"
    # Reset failure count on success
    rm -f /tmp/health_fail_count
    exit 0
else
    # Only notify Discord if the server has successfully started at least once
    # This prevents alerts during the massive 60GB+ initial download/install
    if [[ -f "$READY_FLAG" ]]; then
        log "ERROR" "Server not responding to A2S_INFO on port ${PORT}. Received: ${RESPONSE:-none}"
        
        FAIL_COUNT_FILE="/tmp/health_fail_count"
        COUNT=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0")
        COUNT=$((COUNT + 1))
        echo "$COUNT" > "$FAIL_COUNT_FILE"
        
        # Notify only after 5 consecutive failures post-ready
        if [ "$COUNT" -eq 5 ]; then
            notify_discord "Health Check Failed: Server is no longer responding to A2S_INFO queries." "15158332" "HEALTH_ALERT"
        fi
    else
        log "INFO" "Healthcheck deferred: Server hasn't completed initial boot yet."
    fi
    exit 1
fi
