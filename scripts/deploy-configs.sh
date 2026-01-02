#!/bin/bash
# deploy-configs.sh - Deploy custom configs and mapcycles after game installation
# This script is called from entrypoint-wrapper.sh after SteamCMD completes

source /home/steam/notifications.sh

log "INFO" "Deploying custom configurations for ${CS2_SERVERNAME}..."

# Ensure target directories exist
mkdir -p "/home/steam/cs2-dedicated/game/csgo/cfg"
mkdir -p "/home/steam/cs2-dedicated/game/csgo"

# Determine which config files to deploy based on CS2_GAMEALIAS or CS2_ADDITIONAL_ARGS
CONFIG_FILE=""
MAPCYCLE_SOURCE=""

log "DEBUG" "Checking game mode: CS2_GAMEALIAS=${CS2_GAMEALIAS:-none}, CS2_ADDITIONAL_ARGS=${CS2_ADDITIONAL_ARGS:-none}"

if [[ "${CS2_GAMEALIAS:-}" == "competitive" ]] || [[ "${CS2_ADDITIONAL_ARGS:-}" == *"gamemode_competitive_server.cfg"* ]]; then
    CONFIG_FILE="gamemode_competitive_server.cfg"
    MAPCYCLE_SOURCE="/home/steam/mapcycles/competitive.txt"
elif [[ "${CS2_GAMEALIAS:-}" == "deathmatch" ]] || [[ "${CS2_ADDITIONAL_ARGS:-}" == *"gamemode_deathmatch_server.cfg"* ]]; then
    CONFIG_FILE="gamemode_deathmatch_server.cfg"
    MAPCYCLE_SOURCE="/home/steam/mapcycles/deathmatch.txt"
elif [[ "${CS2_GAMEALIAS:-}" == "retake" ]] || [[ "${CS2_ADDITIONAL_ARGS:-}" == *"gamemode_retake_server.cfg"* ]] || [[ "${CS2_ADDITIONAL_ARGS:-}" == *"sv_skirmish_id 12"* ]]; then
    CONFIG_FILE="gamemode_retake_server.cfg"
    MAPCYCLE_SOURCE="/home/steam/mapcycles/retake.txt"
fi

# Deploy config file if specified
if [ -n "$CONFIG_FILE" ]; then
    if [ -f "/home/steam/configs/${CONFIG_FILE}" ]; then
        log "INFO" "Copying config: /home/steam/configs/${CONFIG_FILE} -> /home/steam/cs2-dedicated/game/csgo/cfg/${CONFIG_FILE}"
        cp -f "/home/steam/configs/${CONFIG_FILE}" "/home/steam/cs2-dedicated/game/csgo/cfg/${CONFIG_FILE}"
        chmod 644 "/home/steam/cs2-dedicated/game/csgo/cfg/${CONFIG_FILE}"
    else
        log "WARN" "Config file not found in staging: /home/steam/configs/${CONFIG_FILE}"
    fi
fi

# Deploy mapcycle if specified
if [ -n "$MAPCYCLE_SOURCE" ]; then
    if [ -f "$MAPCYCLE_SOURCE" ]; then
        log "INFO" "Copying mapcycle: $MAPCYCLE_SOURCE -> /home/steam/cs2-dedicated/game/csgo/mapcycle.txt"
        cp -f "$MAPCYCLE_SOURCE" "/home/steam/cs2-dedicated/game/csgo/mapcycle.txt"
        chmod 644 "/home/steam/cs2-dedicated/game/csgo/mapcycle.txt"
    else
        log "WARN" "Mapcycle source not found: $MAPCYCLE_SOURCE"
    fi
fi

log "INFO" "Configuration deployment complete."
notify_discord "Configuration deployment complete for ${CS2_SERVERNAME}." "3066993" "SUCCESS"
