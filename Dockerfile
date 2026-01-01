# Production-ready CS2 server with operational dependencies
# Extends joedwards32/cs2 with required tooling for healthchecks and notifications

FROM joedwards32/cs2:latest

# Install operational dependencies as root
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        netcat-openbsd && \
    apt-get autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch back to steam user for runtime
USER steam

# Inherit the original entrypoint