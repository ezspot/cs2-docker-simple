#!/bin/bash
# post.sh - Executed after the server stops
source /home/steam/notifications.sh

log "INFO" "Post-stop hook running for ${CS2_SERVERNAME}..."
notify_discord "Server has stopped." "15158332" "STOPPING"
