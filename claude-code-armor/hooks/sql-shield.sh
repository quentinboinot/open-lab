#!/bin/bash
# SQL Shield — Bloque les requetes SQL destructives avant execution
# Event: PreToolUse | Tools: mcp__supabase__execute_sql, mcp__supabase__apply_migration
#
# Usage dans settings.json:
# "hooks": { "PreToolUse": [{ "matcher": "mcp__supabase__execute_sql", "command": "bash ~/.claude/hooks/sql-shield.sh" }] }

INPUT=$(cat -)
SQL=$(echo "$INPUT" | grep -oP '"sql"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$INPUT")

# Patterns destructifs
DANGEROUS_PATTERNS=(
  "DROP\s+TABLE"
  "DROP\s+SCHEMA"
  "DROP\s+DATABASE"
  "TRUNCATE"
  "DELETE\s+FROM\s+\w+\s*$"
  "DELETE\s+FROM\s+\w+\s*;"
  "ALTER\s+TABLE.*DROP\s+COLUMN"
  "DROP\s+INDEX"
  "DROP\s+VIEW"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$SQL" | grep -iP "$pattern" > /dev/null 2>&1; then
    echo "BLOCKED" >&2
    echo '{"error": "SQL Shield: requete destructive bloquee. Pattern: '"$pattern"'. Utilisez --force dans le prompt pour override."}' >&2
    exit 2
  fi
done

exit 0
