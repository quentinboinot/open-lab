#!/bin/bash
# Docker Boot — Auto-start containers MCP au lancement de Claude Code
# Event: SessionStart
#
# Configure via .cc-armor.json:
# { "docker_boot": { "containers": ["mcp-chrome", "mcp-playwright", "camoufox"] } }
# Ou via docker-compose:
# { "docker_boot": { "compose_file": "~/mcp-servers/docker-compose.yml", "services": ["chrome", "playwright"] } }

CONFIG_FILE="${CC_ARMOR_CONFIG:-$HOME/.cc-armor.json}"

if [ ! -f "$CONFIG_FILE" ] || ! command -v jq &> /dev/null; then
  exit 0
fi

# Mode containers individuels
CONTAINERS=$(jq -r '.docker_boot.containers[]? // empty' "$CONFIG_FILE" 2>/dev/null)

if [ -n "$CONTAINERS" ]; then
  while IFS= read -r container; do
    STATUS=$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)
    if [ "$STATUS" != "true" ]; then
      echo "Docker Boot: demarrage $container..." >&2
      docker start "$container" > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo "  OK: $container demarre" >&2
      else
        echo "  WARN: impossible de demarrer $container" >&2
      fi
    else
      echo "Docker Boot: $container deja actif" >&2
    fi
  done <<< "$CONTAINERS"
fi

# Mode docker-compose
COMPOSE_FILE=$(jq -r '.docker_boot.compose_file // empty' "$CONFIG_FILE" 2>/dev/null)
SERVICES=$(jq -r '.docker_boot.services[]? // empty' "$CONFIG_FILE" 2>/dev/null)

if [ -n "$COMPOSE_FILE" ] && [ -f "$(eval echo $COMPOSE_FILE)" ]; then
  COMPOSE_PATH=$(eval echo "$COMPOSE_FILE")
  if [ -n "$SERVICES" ]; then
    echo "Docker Boot: docker-compose up ($COMPOSE_PATH)..." >&2
    docker compose -f "$COMPOSE_PATH" up -d $SERVICES 2>&1 | head -5 >&2
  else
    docker compose -f "$COMPOSE_PATH" up -d 2>&1 | head -5 >&2
  fi
fi

exit 0
