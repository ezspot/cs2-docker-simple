#!/bin/bash
# pre.sh - Executed before the server starts
source /home/steam/notifications.sh

log "INFO" "Pre-start hook running for ${CS2_SERVERNAME}..."

# Check for sufficient disk space (~60GB required for CS2)
FREE_SPACE=$(df -m /home/steam/cs2-dedicated | tail -1 | awk '{print $4}')
if [ "$FREE_SPACE" -lt 61440 ]; then
    log "WARN" "Low disk space detected: ${FREE_SPACE}MB free. CS2 requires ~60GB. This may cause SteamCMD 0x602 errors."
    notify_discord "Warning: Low disk space (${FREE_SPACE}MB free). Update may fail." "16711680" "DISK_LOW"
fi

# Deploy custom configurations after SteamCMD completes
if [ -f /home/steam/deploy-configs.sh ]; then
    /bin/bash /home/steam/deploy-configs.sh
fi

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
