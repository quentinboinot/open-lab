#!/bin/bash
# Ping Stop — Notification externe quand Claude Code termine ou crash
# Event: Stop
#
# Supporte : ntfy.sh (gratuit, zero setup), Telegram Bot, webhook generique
#
# Config via .cc-armor.json:
# ntfy:     { "ping_stop": { "method": "ntfy", "url": "https://ntfy.sh/your-topic" } }
# telegram: { "ping_stop": { "method": "telegram", "bot_token": "xxx", "chat_id": "xxx" } }
# webhook:  { "ping_stop": { "method": "webhook", "url": "https://your-endpoint.com/hook" } }

CONFIG_FILE="${CC_ARMOR_CONFIG:-$HOME/.cc-armor.json}"

if [ ! -f "$CONFIG_FILE" ] || ! command -v jq &> /dev/null; then
  exit 0
fi

ENABLED=$(jq -r '.ping_stop.enabled // true' "$CONFIG_FILE" 2>/dev/null)
if [ "$ENABLED" = "false" ]; then
  exit 0
fi

METHOD=$(jq -r '.ping_stop.method // empty' "$CONFIG_FILE" 2>/dev/null)
TIMESTAMP=$(date '+%H:%M %d/%m')
SESSION_DURATION="${CLAUDE_SESSION_DURATION:-unknown}"
MESSAGE="Claude Code termine a ${TIMESTAMP}. Session: ${SESSION_DURATION}."

case "$METHOD" in
  "ntfy")
    URL=$(jq -r '.ping_stop.url' "$CONFIG_FILE")
    curl -s -d "$MESSAGE" "$URL" > /dev/null 2>&1 &
    ;;
  "telegram")
    BOT_TOKEN=$(jq -r '.ping_stop.bot_token' "$CONFIG_FILE")
    CHAT_ID=$(jq -r '.ping_stop.chat_id' "$CONFIG_FILE")
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      -d "text=${MESSAGE}" \
      -d "parse_mode=Markdown" > /dev/null 2>&1 &
    ;;
  "webhook")
    URL=$(jq -r '.ping_stop.url' "$CONFIG_FILE")
    curl -s -X POST "$URL" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"${MESSAGE}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > /dev/null 2>&1 &
    ;;
  *)
    # Methode non configuree, skip
    ;;
esac

exit 0
