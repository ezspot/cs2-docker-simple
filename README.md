# CS2 Multi-Server Architecture (Docker)

A production-ready, scalable architecture for Counter-Strike 2 dedicated servers.

## Features
- **Official Retakes Support**: Uses `CS2_GAMEALIAS=retake` (Oct 2025 update).
- **Isolated Instances**: Each server has its own `docker-compose.yml` and `.env`.
- **Advanced Healthchecks**: Real-time `A2S_INFO` queries to ensure the Source 2 engine is responding (via `healthcheck.sh`).
- **Discord Notifications**: Rich embed notifications for server status changes (Booting, Errors, Health Alerts) via `notifications.sh`.
- **Scheduled Update Checker**: `update_check.sh` script for background update validation. Configure frequency via `CS2_UPDATE_INTERVAL` (in hours) in `.env`.
- **Instance-Specific Mapcycles**: Each server has its own `mapcycle.txt` for full rotation control.
- **Shared Configs**: Minimal mode-specific overrides in `cfg/`.
- **Hooks**: Expandable pre/post start scripts in `scripts/`.
- **Scalable**: Easily add more servers by copying a server directory.

## Directory Structure
- `cfg/`: Shared read-only configuration overrides.
- `scripts/`: Shared hook scripts (pre.sh, post.sh).
- `servers/`: Individual server instances.

## Quick Start
1. Navigate to a server directory (e.g., `servers/gather1/`).
2. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` and provide your `SRCDS_TOKEN` and other settings.
4. Start the server:
   ```bash
   docker compose up -d
   ```

## Included Servers & Ports
| Server | Mode | CS2 Port | TV Port |
|--------|------|----------|---------|
| gather1 | Competitive | 27015 | 27020 |
| gather2 | Competitive | 27016 | 27021 |
| deathmatch | Deathmatch | 27017 | 27022 |
| retake1 | Retake | 27018 | 27023 |
| retake2 | Retake | 27019 | 27024 |
| retake3 | Retake | 27020 | 27025 |

## Scaling
To add a new server:
1. Create a new directory in `servers/`.
2. Copy `docker-compose.yml` and `.env.example` from an existing server.
3. Update `container_name`, `ports`, `volumes`, and `.env` variables (ensure unique ports).

## Maintenance
- **Updates**: Run `docker compose pull && docker compose up -d` in the server directory.
- **Validation**: Set `STEAMAPPVALIDATE=1` in `.env` to verify files on start.
- **Logs**: Check logs with `docker compose logs -f`.

# Credits
- docker-image: https://github.com/joedwards32/CS2