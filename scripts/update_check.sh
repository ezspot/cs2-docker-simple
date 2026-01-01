#!/bin/bash
# CS2 Scheduled Update Check Script
set -euo pipefail

# Source global logging/notifications
source /home/steam/notifications.sh

STEAMAPPDIR="${STEAMAPPDIR:-/home/steam/cs2-dedicated}"
STEAMCMDDIR="${STEAMCMDDIR:-/home/steam/steamcmd}"
STEAMAPPID="${STEAMAPPID:-730}"

log "INFO" "Scheduled update check initiated..."

# Run SteamCMD update with validation
# We don't notify Discord unless an actual update starts or fails
"${STEAMCMDDIR}/steamcmd.sh" \
    +force_install_dir "${STEAMAPPDIR}" \
    +@sSteamCmdForcePlatformType linux \
    +login anonymous \
    +app_update "${STEAMAPPID}" validate \
    +quit || {
        log "ERROR" "Scheduled update check failed."
        notify_discord "Scheduled update check failed." "15158332" "ERROR"
        exit 1
    }

log "INFO" "Update check completed. Server will restart if Docker detects a change or if we trigger it."
