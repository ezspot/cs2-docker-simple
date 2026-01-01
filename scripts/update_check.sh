#!/bin/bash
# CS2 Scheduled Update Check Script with Match-Hour Awareness
set -euo pipefail

# Source global logging/notifications
source /home/steam/notifications.sh

STEAMAPPDIR="${STEAMAPPDIR:-/home/steam/cs2-dedicated}"
STEAMCMDDIR="${STEAMCMDDIR:-/home/steam/steamcmd}"
STEAMAPPID="${STEAMAPPID:-730}"
INTERVAL_HOURS="${CS2_UPDATE_INTERVAL:-0}"
MATCH_HOURS="${CS2_UPDATE_MATCH_HOURS:-}"  # e.g., "18-23" to block updates 6pm-11pm
RESTART_MARKER="/tmp/restart_required"

# Check if current hour is within match hours (when updates should be blocked)
is_match_hour() {
    if [[ -z "$MATCH_HOURS" ]]; then
        return 1  # No match hours defined, not in match hour
    fi
    
    local current_hour=$(date +%H | sed 's/^0//')
    local start_hour=$(echo "$MATCH_HOURS" | cut -d'-' -f1 | sed 's/^0//')
    local end_hour=$(echo "$MATCH_HOURS" | cut -d'-' -f2 | sed 's/^0//')
    
    if [[ $current_hour -ge $start_hour && $current_hour -le $end_hour ]]; then
        return 0  # In match hour
    fi
    return 1  # Not in match hour
}

run_update() {
    # Check if we're in match hours
    if is_match_hour; then
        log "INFO" "Skipping update check - currently in match hours ($MATCH_HOURS)"
        return 0
    fi
    
    log "INFO" "Update check initiated..."
    
    # Capture manifest before update
    local manifest_before=""
    if [[ -f "${STEAMAPPDIR}/steamapps/appmanifest_${STEAMAPPID}.acf" ]]; then
        manifest_before=$(md5sum "${STEAMAPPDIR}/steamapps/appmanifest_${STEAMAPPID}.acf" 2>/dev/null | cut -d' ' -f1)
    fi
    
    # Run SteamCMD update
    "${STEAMCMDDIR}/steamcmd.sh" \
        +force_install_dir "${STEAMAPPDIR}" \
        +@sSteamCmdForcePlatformType linux \
        +login anonymous \
        +app_update "${STEAMAPPID}" validate \
        +quit || {
            log "ERROR" "Update check failed."
            notify_discord "Scheduled update check failed." "15158332" "ERROR"
            return 1
        }
    
    # Check if manifest changed (indicating an update occurred)
    local manifest_after=""
    if [[ -f "${STEAMAPPDIR}/steamapps/appmanifest_${STEAMAPPID}.acf" ]]; then
        manifest_after=$(md5sum "${STEAMAPPDIR}/steamapps/appmanifest_${STEAMAPPID}.acf" 2>/dev/null | cut -d' ' -f1)
    fi
    
    if [[ -n "$manifest_before" && -n "$manifest_after" && "$manifest_before" != "$manifest_after" ]]; then
        log "INFO" "CS2 update detected! Server restart required."
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Update detected, restart required" > "$RESTART_MARKER"
        notify_discord "🔄 CS2 update detected! Server restart required. Restart marker created at $RESTART_MARKER" "16776960" "UPDATED"
    else
        log "INFO" "Update check completed. Server is up to date."
    fi
}

if [ "$INTERVAL_HOURS" -gt 0 ]; then
    log "INFO" "Auto-update loop started. Checking every ${INTERVAL_HOURS} hour(s)."
    if [[ -n "$MATCH_HOURS" ]]; then
        log "INFO" "Match hours configured: $MATCH_HOURS (updates will be skipped during these hours)"
    fi
    
    while true; do
        run_update || true
        sleep $((INTERVAL_HOURS * 3600))
    done
else
    run_update
fi
