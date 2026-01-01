#!/bin/bash
set -eou pipefail

# Healthcheck script for CS2 Docker
# Performs a real A2S_INFO query to ensure the Source 2 engine is responding

PORT=${CS2_PORT:-27015}
TIMEOUT=5

# Import central logging & notification service
source /home/steam/notifications.sh

# Check if we are currently in the SteamCMD update/install phase
if command -v pgrep >/dev/null 2>&1; then
    if pgrep -f "steamcmd.sh" > /dev/null; then
        log "INFO" "Healthcheck deferred: SteamCMD update in progress."
        exit 0
    fi
else
    # Fallback if pgrep is missing (though procps is in Dockerfile)
    if ps aux | grep -v grep | grep -q "steamcmd.sh"; then
        log "INFO" "Healthcheck deferred: SteamCMD update in progress (ps fallback)."
        exit 0
    fi
fi

# A2S_INFO Request: FFFFFFFF 54 53 6f 75 72 63 65 20 45 6e 67 69 6e 65 20 51 75 65 72 79 00
# \xff\xff\xff\xffTSource Engine Query\0
QUERY=$(printf "\xff\xff\xff\xffTSource Engine Query\0")

# Check if server responds to A2S_INFO
# The response starts with 4x 0xFF followed by 'I' (0x49)
RESPONSE=$(echo -ne "$QUERY" | nc -u -w "$TIMEOUT" 127.0.0.1 "$PORT" | head -c 5 | od -An -t x1 | tr -d ' ' || true)

if [[ "$RESPONSE" == "ffffffff49" ]]; then
    exit 0
else
    log "ERROR" "Server is not responding to A2S_INFO on port ${PORT}. Received: ${RESPONSE:-none}"
    notify_discord "Health Check Failed: Server is not responding to A2S_INFO queries." "15158332" "HEALTH_ALERT"
    exit 1
fi
