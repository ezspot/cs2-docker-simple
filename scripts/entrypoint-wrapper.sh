#!/bin/bash
# Entrypoint wrapper to load Docker secrets into environment variables
# This allows the joedwards32/cs2 image to work with Docker secrets

set -e

# Verify required dependencies are present (installed at build time)
for cmd in nc jq curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "[ENTRYPOINT] ERROR: Required dependency '$cmd' not found. Image may be outdated."
    fi
done

# Detect which server this is based on container name or mounted secrets
# Read per-server secrets and export as environment variables
SERVER_PREFIX=""
if [[ -d /run/secrets ]]; then
    for secret_file in /run/secrets/*_srcds_token; do
        if [[ -f "$secret_file" ]]; then
            SERVER_PREFIX=$(basename "$secret_file" | sed 's/_srcds_token//')
            break
        fi
    done
fi

if [[ -n "$SERVER_PREFIX" ]]; then
    echo "[ENTRYPOINT] Loading secrets for server: $SERVER_PREFIX"
    
    # Load SRCDS token
    if [[ -f "/run/secrets/${SERVER_PREFIX}_srcds_token" ]]; then
        export SRCDS_TOKEN=$(cat "/run/secrets/${SERVER_PREFIX}_srcds_token")
    fi
    
    # Load RCON password
    if [[ -f "/run/secrets/${SERVER_PREFIX}_rcon_password" ]]; then
        export CS2_RCONPW=$(cat "/run/secrets/${SERVER_PREFIX}_rcon_password")
    fi
    
    # Load Discord webhook
    if [[ -f "/run/secrets/${SERVER_PREFIX}_discord_webhook" ]]; then
        WEBHOOK_VAL=$(cat "/run/secrets/${SERVER_PREFIX}_discord_webhook")
        if [[ -n "$WEBHOOK_VAL" && "$WEBHOOK_VAL" != "YOUR_WEBHOOK_URL" ]]; then
            export DISCORD_WEBHOOK_URL="$WEBHOOK_VAL"
        fi
    fi
else
    echo "[ENTRYPOINT] Warning: Could not detect server prefix from secrets"
fi

# Execute the original entrypoint
exec /home/steam/entry.sh "$@"
