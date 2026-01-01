#!/bin/bash
# pre.sh - Executed before the server starts
source /home/steam/notifications.sh

log "INFO" "Pre-start hook running for ${CS2_SERVERNAME}..."
notify_discord "Server is booting up..." "3447003" "BOOTING"

if [ "${STEAMAPPVALIDATE:-0}" == "1" ]; then
    log "INFO" "Validation enabled, checking for updates/corruption..."
    notify_discord "Validating server files..." "15844367" "UPDATING"
fi
