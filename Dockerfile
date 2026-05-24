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

COPY --chown=hermes:hermes skills/ ${HERMES_HOME}/skills/
COPY --chown=hermes:hermes config/config.yaml ${HERMES_HOME}/config.yaml
COPY --chown=hermes:hermes SOUL.md ${HERMES_HOME}/SOUL.md
