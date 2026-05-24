# Hermes Agent — Custom Cloud Image
# Extends the official NousResearch image with custom skills and config
#
# Base: https://hub.docker.com/r/nousresearch/hermes-agent
# Repo: https://github.com/NousResearch/hermes-agent

FROM docker.io/nousresearch/hermes-agent:v2026.5.7

# Install additional system dependencies (if needed by tools)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Stay as root so the start command can chown the Railway-mounted volume.
# The entrypoint.sh handles dropping to the hermes user internally.

# Copy config to /opt/hermes/ (outside the /opt/data volume mount) so it
# survives the Railway volume overlay. Set HERMES_CONFIG=/opt/hermes/config.yaml
# in Railway Variables to make Hermes read from here instead of /opt/data.
COPY --chown=hermes:hermes config/config.yaml /opt/hermes/config.yaml
COPY --chown=hermes:hermes SOUL.md /opt/hermes/SOUL.md
