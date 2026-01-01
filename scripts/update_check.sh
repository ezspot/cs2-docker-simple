#!/bin/bash
# CS2 Scheduled Update Check Script
set -euo pipefail

# Source global logging/notifications
source /home/steam/notifications.sh

STEAMAPPDIR="${STEAMAPPDIR:-/home/steam/cs2-dedicated}"
STEAMCMDDIR="${STEAMCMDDIR:-/home/steam/steamcmd}"
STEAMAPPID="${STEAMAPPID:-730}"
INTERVAL_HOURS="${CS2_UPDATE_INTERVAL:-0}"

run_update() {
    log "INFO" "Update check initiated..."
    
    # We use a temporary file to check if SteamCMD actually updated something
    # This is a simplified check. In production, one might check manifest files.
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
    
    log "INFO" "Update check completed. If files were updated, server requires restart (handled by container restart policy if app crashes on version mismatch, or manual)."
}

if [ "$INTERVAL_HOURS" -gt 0 ]; then
    log "INFO" "Auto-update loop started. Checking every ${INTERVAL_HOURS} hour(s)."
    while true; do
        run_update || true
        sleep $((INTERVAL_HOURS * 3600))
    done
else
    run_update
fi
