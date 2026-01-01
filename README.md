# CS2 Multi-Server Production Architecture

**Production-ready, DevSecOps-hardened Counter-Strike 2 dedicated server infrastructure for January 2026.**

Designed for deterministic deployments, zero secret leakage, minimal drift, and stable 18-player performance on physical hardware.

The project uses a custom Docker image that extends `joedwards32/cs2:latest` with operational dependencies (netcat, jq, curl) required for healthchecks and notifications.

---

## Features

- **🔐 Secrets Management**: Docker secrets integration for SRCDS tokens, RCON passwords, and Discord webhooks
- **🎯 Zero Duplication**: Single `docker-compose.yml` with YAML anchors for all 6 servers
- **🛡️ Security Hardened**: `no-new-privileges`, capability dropping, read-only tmpfs, pids limits
- **⚡ Performance Tuned**: CPU pinning, memory limits, ulimits for 18-player stability
- **🔄 Smart Updates**: Match-hour awareness, restart markers, Discord notifications on updates
- **💚 Advanced Healthchecks**: Real `A2S_INFO` queries with deferred checks during updates
- **📊 Observability**: Discord webhook notifications for all lifecycle events

---

## Quick Start

### 1. Setup Secrets (First Time Only)

```bash
# Create all per-server secret files from examples
cd secrets/
for server in gather1 gather2 deathmatch retake1 retake2 retake3; do
  cp ${server}_srcds_token.txt.example ${server}_srcds_token.txt
  cp ${server}_rcon_password.txt.example ${server}_rcon_password.txt
  cp ${server}_discord_webhook.txt.example ${server}_discord_webhook.txt
done

# Edit with your actual credentials (example for gather1)
nano gather1_srcds_token.txt      # Add SRCDS token from https://steamcommunity.com/dev/managegameservers
nano gather1_rcon_password.txt    # Add strong RCON password (unique per server)
nano gather1_discord_webhook.txt  # Add Discord webhook URL

# Repeat for other servers or reuse same token/webhook if preferred
# Best practice: unique RCON passwords per server, can share SRCDS token

# Secure permissions (Linux/macOS)
chmod 600 *_srcds_token.txt *_rcon_password.txt *_discord_webhook.txt
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit configuration (optional - defaults are production-ready)
nano .env
```

### 3. Deploy All Servers

```bash
# Start all 6 servers
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f gather1
```

---

## Architecture

### Directory Structure

```
cs2-docker-simple/
├── docker-compose.yml          # Single consolidated compose file (all 6 servers)
├── .env                        # Non-sensitive configuration (gitignored)
├── .env.example                # Template with safe defaults
├── secrets/                    # Per-server credentials (gitignored)
│   ├── gather1_srcds_token.txt
│   ├── gather1_rcon_password.txt
│   ├── gather1_discord_webhook.txt
│   ├── gather2_srcds_token.txt
│   ├── gather2_rcon_password.txt
│   ├── gather2_discord_webhook.txt
│   └── ... (retake1, retake2, retake3, deathmatch)
├── cfg/                        # Shared game mode configs (read-only)
│   ├── gamemode_competitive_server.cfg
│   ├── gamemode_deathmatch_server.cfg
│   └── gamemode_retake_server.cfg
├── scripts/                    # Shared operational scripts (read-only)
│   ├── entrypoint-wrapper.sh   # Secrets loader + dependency installer
│   ├── pre.sh                  # Pre-start hook
│   ├── post.sh                 # Post-start hook
│   ├── notifications.sh        # Discord notification library
│   ├── healthcheck.sh          # A2S_INFO healthcheck
│   └── update_check.sh         # Smart update checker
└── servers/                    # Per-server data and configs
    ├── gather1/
    │   ├── data/               # Game files (bind mount, gitignored)
    │   └── mapcycle.txt        # Instance-specific map rotation
    ├── gather2/
    ├── deathmatch/
    ├── retake1/
    ├── retake2/
    └── retake3/
```

### Server Configuration

| Server | Mode | Game Port | TV Port | CPU Cores | Memory |
|--------|------|-----------|---------|-----------|--------|
| gather1 | Competitive | 27015 | 27020 | 0-1 | 4GB |
| gather2 | Competitive | 27016 | 27021 | 2-3 | 4GB |
| deathmatch | Deathmatch | 27017 | 27022 | 4-5 | 4GB |
| retake1 | Retake | 27018 | 27023 | 6-7 | 4GB |
| retake2 | Retake | 27019 | 27024 | 8-9 | 4GB |
| retake3 | Retake | 27020 | 27025 | 10-11 | 4GB |

---

## Operational Runbook

### Starting & Stopping Individual Servers

One of the main benefits of this structure is independent management:

```bash
# Start/Restart only gather1
docker compose up -d gather1

# Stop only retake2
docker compose stop retake2

# Restart only deathmatch
docker compose restart deathmatch

# View logs for just one server
docker compose logs -f gather2
```

### Stopping Servers

```bash
# Stop all servers gracefully
docker compose down

# Stop specific server
docker compose stop gather1

# Force stop (not recommended)
docker compose kill gather1
```

### Viewing Logs

```bash
# Follow logs for all servers
docker compose logs -f

# Follow logs for specific server
docker compose logs -f gather1

# View last 100 lines
docker compose logs --tail=100 gather1

# View logs with timestamps
docker compose logs -f -t gather1
```

### Checking Server Status

```bash
# View all containers
docker compose ps

# Check healthcheck status
docker compose ps gather1

# Inspect container details
docker inspect cs2-gather1

# Check restart marker (indicates update available)
docker exec cs2-gather1 cat /tmp/restart_required
```

### Restarting Servers

```bash
# Restart specific server (graceful)
docker compose restart gather1

# Restart all servers
docker compose restart

# Restart after update detection
docker compose restart gather1 && docker exec cs2-gather1 rm -f /tmp/restart_required
```

### Updating Game Files

```bash
# Manual update check (runs immediately)
docker exec cs2-gather1 /bin/bash /home/steam/update_check.sh

# Automatic updates are handled by CS2_UPDATE_INTERVAL in .env
# Updates respect CS2_UPDATE_MATCH_HOURS to avoid disrupting matches
```

### Rotating Secrets

```bash
# 1. Update secret file
nano secrets/rcon_password.txt

# 2. Restart affected servers to pick up new secret
docker compose restart

# 3. Verify new secret is loaded
docker compose logs gather1 | grep -i "starting"
```

### Scaling - Adding New Server

```bash
# 1. Create server data directory
mkdir -p servers/gather3/data

# 2. Create mapcycle file
cp servers/gather1/mapcycle.txt servers/gather3/mapcycle.txt

# 3. Edit docker-compose.yml and add new service block
# 4. Update .env with new server variables (GATHER3_*)

# 5. Start new server
docker compose up -d gather3
```

---

## Troubleshooting

### Healthcheck Failing

**Symptom**: Container shows `unhealthy` status

```bash
# Check if server is actually running
docker exec cs2-gather1 pgrep -f cs2

# Check if ports are bound
docker exec cs2-gather1 netstat -tulpn | grep 27015

# View healthcheck logs
docker compose logs gather1 | grep -i health

# Check for SteamCMD activity (healthcheck defers during updates)
docker exec cs2-gather1 pgrep steamcmd

# Manually run healthcheck
docker exec cs2-gather1 /bin/bash /home/steam/healthcheck.sh
```

**Common Causes**:
- Server still downloading game files (first boot takes 10-20 min)
- SteamCMD update in progress (healthcheck automatically defers)
- Port conflict with another service
- Insufficient memory (check `docker stats`)

### Server Won't Start

**Symptom**: Container exits immediately or restarts repeatedly

```bash
# Check container logs
docker compose logs --tail=100 gather1

# Check for port conflicts
sudo netstat -tulpn | grep 27015

# Verify secrets exist
ls -la secrets/*.txt

# Check disk space
df -h

# Verify permissions on data directory
ls -la servers/gather1/
```

**Common Causes**:
- Missing or invalid SRCDS token in `secrets/srcds_token.txt`
- Port already in use by another service
- Insufficient disk space (CS2 requires ~30GB per instance)
- Corrupted game files (delete `servers/*/data/` and restart)

### SteamCMD 0x602 Error

**Symptom**: Update fails with error code `0x602`

```bash
# Check disk space and I/O
df -h
iostat -x 1 5

# Check for disk errors
dmesg | grep -i error

# Verify data directory is writable
docker exec cs2-gather1 touch /home/steam/cs2-dedicated/test && docker exec cs2-gather1 rm /home/steam/cs2-dedicated/test
```

**Solutions**:
- Ensure sufficient disk space (30GB+ free per server)
- Use fast storage (NVMe SSD recommended)
- Disable validation temporarily: set `STEAMAPPVALIDATE=0` in `.env`
- Check filesystem for errors: `sudo fsck /dev/sdX`

### Discord Notifications Not Working

```bash
# Verify webhook URL is correct
docker exec cs2-gather1 cat /run/secrets/discord_webhook

# Test webhook manually
curl -H "Content-Type: application/json" -X POST -d '{"content":"Test message"}' $(docker exec cs2-gather1 cat /run/secrets/discord_webhook)

# Check notification script
docker exec cs2-gather1 cat /home/steam/notifications.sh
```

### Performance Issues

```bash
# Check resource usage
docker stats

# Check CPU throttling
docker exec cs2-gather1 cat /sys/fs/cgroup/cpu/cpu.stat

# Verify CPU pinning
docker inspect cs2-gather1 | grep -i cpuset

# Check network latency
docker exec cs2-gather1 ping -c 5 8.8.8.8
```

**Optimization**:
- Adjust `cpuset_cpus` in `.env` to match your CPU topology
- Increase `mem_limit` if servers have >16 players
- Ensure host system has `performance` CPU governor
- Disable unnecessary background services on host

### Update Not Applying

```bash
# Check for restart marker
docker exec cs2-gather1 cat /tmp/restart_required

# Verify update checker is running
docker exec cs2-gather1 pgrep -f update_check.sh

# Check match hours configuration
docker exec cs2-gather1 env | grep MATCH_HOURS

# Manually trigger update
docker exec cs2-gather1 /bin/bash /home/steam/update_check.sh
```

---

## Security Best Practices

1. **Never commit secrets**: All `secrets/*.txt` and `.env` files are gitignored
2. **Rotate credentials regularly**: Update secrets every 90 days minimum
3. **Use strong RCON passwords**: Minimum 12 characters, alphanumeric + symbols
4. **Restrict Discord webhooks**: Use channel-specific webhooks, not server-wide
5. **Monitor logs**: Check for unauthorized RCON attempts
6. **Keep Docker updated**: Run `docker version` and update regularly
7. **Firewall rules**: Only expose game ports (27015-27025), block Docker API

---

## Performance Tuning

### Linux Kernel Optimization

```bash
# Set CPU governor to performance
echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Increase network buffers
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Reduce swappiness
sudo sysctl -w vm.swappiness=10

# Make permanent
sudo nano /etc/sysctl.conf
```

### Docker Optimization

```bash
# Use overlay2 storage driver
docker info | grep "Storage Driver"

# Prune unused resources weekly
docker system prune -af --volumes

# Monitor disk usage
docker system df
```

---

## References

- **CS2 Dedicated Servers**: https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers
- **Docker Compose Docs**: https://docs.docker.com/compose/
- **Discord Webhooks**: https://discord.com/developers/docs/resources/webhook
- **Base Docker Image**: https://github.com/joedwards32/CS2

---

## License

This configuration is provided as-is for production use. Modify as needed for your infrastructure.