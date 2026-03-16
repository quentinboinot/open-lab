#!/bin/bash
# MCP Rate Guard — Rate limiting configurable par outil MCP
# Event: PreToolUse | Configurable via CC_ARMOR_CONFIG ou ~/.cc-armor.json
#
# Config exemple dans .cc-armor.json:
# { "rate_guard": { "rules": { "instagram_*": { "max": 30, "window": 3600 }, "camoufox_*": { "max": 10, "window": 60 } } } }

CONFIG_FILE="${CC_ARMOR_CONFIG:-$HOME/.cc-armor.json}"
RATE_FILE="/tmp/cc-armor-rates.json"
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"

# Init rate file si inexistant
[ ! -f "$RATE_FILE" ] && echo '{}' > "$RATE_FILE"

# Charger config
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0  # Pas de config = pas de rate limiting
fi

# Lire les regles (necessite jq si disponible, sinon skip)
if ! command -v jq &> /dev/null; then
  exit 0  # jq pas installe, skip le rate limiting
fi

RULES=$(jq -r '.rate_guard.rules // {} | to_entries[] | "\(.key) \(.value.max) \(.value.window)"' "$CONFIG_FILE" 2>/dev/null)

if [ -z "$RULES" ]; then
  exit 0
fi

NOW=$(date +%s)

while IFS=' ' read -r pattern max_calls window_secs; do
  # Matcher le pattern (glob style)
  REGEX=$(echo "$pattern" | sed 's/\*/.*/' )
  if echo "$TOOL_NAME" | grep -qP "$REGEX"; then
    # Compter les appels dans la fenetre
    CALLS=$(jq -r --arg tool "$TOOL_NAME" --argjson cutoff "$((NOW - window_secs))" \
      '(.[$tool] // []) | map(select(. > $cutoff)) | length' "$RATE_FILE" 2>/dev/null || echo "0")

    if [ "$CALLS" -ge "$max_calls" ]; then
      echo "BLOCKED" >&2
      echo "{\"error\": \"MCP Rate Guard: $TOOL_NAME limite a $max_calls appels par ${window_secs}s. Attendez.\"}" >&2
      exit 2
    fi

    # Enregistrer l'appel
    jq --arg tool "$TOOL_NAME" --argjson ts "$NOW" \
      '.[$tool] = ((.[$tool] // []) + [$ts])' "$RATE_FILE" > "${RATE_FILE}.tmp" && mv "${RATE_FILE}.tmp" "$RATE_FILE"
    break
  fi
done <<< "$RULES"

exit 0
