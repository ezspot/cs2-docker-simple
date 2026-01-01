#!/bin/bash
# pre.sh - Executed before the server starts
source /home/steam/notifications.sh

log "INFO" "Pre-start hook running for ${CS2_SERVERNAME}..."
# Reset health failure count and ready flag
rm -f /tmp/health_fail_count
rm -f /tmp/server_ready
notify_discord "Server is booting up..." "3447003" "BOOTING"

if [ "${STEAMAPPVALIDATE:-0}" == "1" ]; then
    log "INFO" "Validation enabled, checking for updates/corruption..."
    notify_discord "Validating server files..." "15844367" "UPDATING"
fi

# Start update checker in background if interval is set
if [ "${CS2_UPDATE_INTERVAL:-0}" -gt 0 ]; then
    log "INFO" "Starting background update checker (Interval: ${CS2_UPDATE_INTERVAL}h)"
    /bin/bash /home/steam/update_check.sh &
fi
