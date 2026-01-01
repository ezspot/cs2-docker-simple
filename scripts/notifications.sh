#!/bin/bash

# Centralized Logging and Notification Service for CS2 Docker
# Handles stdout logging and Discord webhooks with rich embeds

log() {
    local level=${1:-INFO}
    shift
    local message="$*"
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [$level] $message"
}

notify_discord() {
    local message=$1
    local color=${2:-3447003} # Default blue
    local status=${3:-"INFO"}
    
    if [[ -z "${DISCORD_WEBHOOK_URL:-}" ]]; then
        return 0
    fi

    # Mapping status to icons
    local icon="❓"
    case "$status" in
        BOOTING) icon="🚀" ;;
        UPDATING) icon="🔄" ;;
        UPDATED) icon="✅" ;;
        STARTING) icon="🎮" ;;
        STOPPING) icon="🛑" ;;
        ERROR) icon="❌" ;;
        HEALTH_ALERT) icon="🚨" ;;
        *) icon="ℹ️" ;;
    esac

    local payload
    payload=$(jq -n \
        --arg msg "$message" \
        --arg color "$color" \
        --arg status "$status" \
        --arg icon "$icon" \
        --arg host "${CS2_SERVERNAME:-CS2 Server}" \
        '{
            embeds: [{
                author: {
                    name: $host
                },
                title: ($icon + " Status: " + $status),
                description: $msg,
                color: ($color | tonumber),
                timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
                footer: {
                    text: "CS2 Dedicated Server Service"
                }
            }]
        }')

    curl -s -H "Content-Type: application/json" -X POST -d "$payload" "$DISCORD_WEBHOOK_URL" > /dev/null || echo "Failed to send Discord notification"
}
