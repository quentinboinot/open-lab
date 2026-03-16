#!/bin/bash
# MCP Logger — Log chaque appel MCP en JSONL avec rotation quotidienne
# Event: PostToolUse
#
# Les logs sont ecrits dans ~/.claude/logs/mcp-calls.log (JSONL)
# Rotation automatique : les logs de la veille sont archives en .log.YYYY-MM-DD

LOG_DIR="${HOME}/.claude/logs"
LOG_FILE="${LOG_DIR}/mcp-calls.log"
TODAY=$(date +%Y-%m-%d)

# Creer le dossier si inexistant
mkdir -p "$LOG_DIR"

# Rotation : si le fichier existe et date d'un autre jour, archiver
if [ -f "$LOG_FILE" ]; then
  FILE_DATE=$(date -r "$LOG_FILE" +%Y-%m-%d 2>/dev/null || echo "$TODAY")
  if [ "$FILE_DATE" != "$TODAY" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.${FILE_DATE}" 2>/dev/null
    # Garder seulement les 7 derniers jours
    find "$LOG_DIR" -name "mcp-calls.log.*" -mtime +7 -delete 2>/dev/null
  fi
fi

# Lire l'input (tool result)
INPUT=$(cat -)
TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DURATION="${CLAUDE_TOOL_DURATION_MS:-0}"
STATUS="${CLAUDE_TOOL_STATUS:-success}"

# Ecrire le log en JSONL (une ligne JSON)
echo "{\"ts\":\"${TIMESTAMP}\",\"tool\":\"${TOOL_NAME}\",\"status\":\"${STATUS}\",\"duration_ms\":${DURATION}}" >> "$LOG_FILE"

exit 0
