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

# Switch back to the hermes user
USER hermes

# Copy custom skills into the skills directory
# These are loaded automatically by Hermes on startup
COPY --chown=hermes:hermes skills/ ${HERMES_HOME}/skills/

# Copy base config (no secrets — secrets go in .env on persistent disk)
COPY --chown=hermes:hermes config/config.yaml ${HERMES_HOME}/config.yaml

# Copy SOUL.md (personality file)
COPY --chown=hermes:hermes SOUL.md ${HERMES_HOME}/SOUL.md

# Note: .env with API keys is NOT baked into the image.
# Set it via the Hermes dashboard after first boot, or via Render's
# Environment tab. The persistent disk keeps it across deploys.
