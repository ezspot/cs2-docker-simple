#!/bin/bash
# deploy-configs.sh - Deploy custom configs and mapcycles after game installation
# This script is called from entrypoint-wrapper.sh after SteamCMD completes

source /home/steam/notifications.sh

log "INFO" "Deploying custom configurations for ${CS2_SERVERNAME}..."

# Determine which config files to deploy based on CS2_GAMEALIAS or CS2_ADDITIONAL_ARGS
CONFIG_FILE=""
MAPCYCLE_SOURCE=""

if [[ "${CS2_GAMEALIAS}" == "competitive" ]] || [[ "${CS2_ADDITIONAL_ARGS}" == *"gamemode_competitive_server.cfg"* ]]; then
    CONFIG_FILE="gamemode_competitive_server.cfg"
    MAPCYCLE_SOURCE="/home/steam/mapcycles/competitive.txt"
elif [[ "${CS2_GAMEALIAS}" == "deathmatch" ]] || [[ "${CS2_ADDITIONAL_ARGS}" == *"gamemode_deathmatch_server.cfg"* ]]; then
    CONFIG_FILE="gamemode_deathmatch_server.cfg"
    MAPCYCLE_SOURCE="/home/steam/mapcycles/deathmatch.txt"
elif [[ "${CS2_GAMEALIAS}" == "retake" ]] || [[ "${CS2_ADDITIONAL_ARGS}" == *"gamemode_retake_server.cfg"* ]]; then
    CONFIG_FILE="gamemode_retake_server.cfg"
    MAPCYCLE_SOURCE="/home/steam/mapcycles/retake.txt"
fi

# Deploy config file if specified
if [ -n "$CONFIG_FILE" ] && [ -f "/home/steam/configs/${CONFIG_FILE}" ]; then
    log "INFO" "Deploying ${CONFIG_FILE}..."
    cp -f "/home/steam/configs/${CONFIG_FILE}" "/home/steam/cs2-dedicated/game/csgo/cfg/${CONFIG_FILE}"
    chmod 644 "/home/steam/cs2-dedicated/game/csgo/cfg/${CONFIG_FILE}"
fi

# Deploy mapcycle if specified
if [ -n "$MAPCYCLE_SOURCE" ] && [ -f "$MAPCYCLE_SOURCE" ]; then
    log "INFO" "Deploying mapcycle from ${MAPCYCLE_SOURCE}..."
    cp -f "$MAPCYCLE_SOURCE" "/home/steam/cs2-dedicated/game/csgo/mapcycle.txt"
    chmod 644 "/home/steam/cs2-dedicated/game/csgo/mapcycle.txt"
fi

log "INFO" "Configuration deployment complete."
