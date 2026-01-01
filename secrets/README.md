# Secrets Management - Per-Server Architecture

This directory contains sensitive credentials for CS2 servers. **Never commit actual secret files to git.**

Each server has its own isolated secrets for maximum security and flexibility.

## Setup Instructions

### Quick Setup (All Servers)
```bash
# Create all secret files from examples
for server in gather1 gather2 deathmatch retake1 retake2 retake3; do
  cp ${server}_srcds_token.txt.example ${server}_srcds_token.txt
  cp ${server}_rcon_password.txt.example ${server}_rcon_password.txt
  cp ${server}_discord_webhook.txt.example ${server}_discord_webhook.txt
done

# Secure permissions (Linux/macOS)
chmod 600 *_srcds_token.txt *_rcon_password.txt *_discord_webhook.txt
```

### Manual Setup (Per Server)
```bash
# Example for gather1
cp gather1_srcds_token.txt.example gather1_srcds_token.txt
cp gather1_rcon_password.txt.example gather1_rcon_password.txt
cp gather1_discord_webhook.txt.example gather1_discord_webhook.txt

# Edit with actual credentials
nano gather1_srcds_token.txt      # Add SRCDS token
nano gather1_rcon_password.txt    # Add RCON password
nano gather1_discord_webhook.txt  # Add Discord webhook URL

# Repeat for other servers (gather2, deathmatch, retake1, retake2, retake3)
```

## Credential Details

### SRCDS Token (per server)
- Get from: https://steamcommunity.com/dev/managegameservers
- **Best Practice**: Use different tokens per server for isolation
- **Alternative**: Can reuse same token across servers (less secure)

### RCON Password (per server)
- **Must be unique per server** for security
- Minimum 12 characters recommended
- Use alphanumeric + symbols
- Example: `Gather1_Rc0n!2026`

### Discord Webhook (per server)
- Get from: Discord Server Settings → Integrations → Webhooks
- **Best Practice**: Use different webhooks/channels per server for clarity
- **Alternative**: Can reuse same webhook (all notifications in one channel)

## Security Notes

- All `*.txt` files (except `.example`) are excluded from git via `.gitignore`
- Docker Compose mounts these as read-only secrets per container
- Each server only has access to its own secrets (isolation)
- Rotate credentials every 90 days minimum (see main README)
- Never log or expose these values in scripts or environment variables

## File Structure

```
secrets/
├── gather1_srcds_token.txt         # Gather 1 Steam token
├── gather1_rcon_password.txt       # Gather 1 RCON password
├── gather1_discord_webhook.txt     # Gather 1 Discord webhook
├── gather2_srcds_token.txt         # Gather 2 Steam token
├── gather2_rcon_password.txt       # Gather 2 RCON password
├── gather2_discord_webhook.txt     # Gather 2 Discord webhook
├── deathmatch_srcds_token.txt      # Deathmatch Steam token
├── deathmatch_rcon_password.txt    # Deathmatch RCON password
├── deathmatch_discord_webhook.txt  # Deathmatch Discord webhook
├── retake1_srcds_token.txt         # Retake 1 Steam token
├── retake1_rcon_password.txt       # Retake 1 RCON password
├── retake1_discord_webhook.txt     # Retake 1 Discord webhook
├── retake2_srcds_token.txt         # Retake 2 Steam token
├── retake2_rcon_password.txt       # Retake 2 RCON password
├── retake2_discord_webhook.txt     # Retake 2 Discord webhook
├── retake3_srcds_token.txt         # Retake 3 Steam token
├── retake3_rcon_password.txt       # Retake 3 RCON password
└── retake3_discord_webhook.txt     # Retake 3 Discord webhook
```
