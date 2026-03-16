#!/bin/bash
# Quality Gate — Checklist automatique avant de closer une tache
# Event: TaskCompleted
#
# Configure via .cc-armor.json:
# { "quality_gate": { "checks": ["no_console_log", "no_env_secrets", "has_docstrings"] } }

CONFIG_FILE="${CC_ARMOR_CONFIG:-$HOME/.cc-armor.json}"
FAILED=0

# Charger la config
if [ ! -f "$CONFIG_FILE" ] || ! command -v jq &> /dev/null; then
  exit 0
fi

CHECKS=$(jq -r '.quality_gate.checks[]? // empty' "$CONFIG_FILE" 2>/dev/null)

if [ -z "$CHECKS" ]; then
  exit 0
fi

echo "Quality Gate — verification en cours..." >&2

while IFS= read -r check; do
  case "$check" in
    "no_console_log")
      # Verifier qu'il n'y a pas de console.log dans les fichiers modifies
      if git diff --cached --name-only 2>/dev/null | xargs grep -l "console\.log" 2>/dev/null | head -1 | grep -q .; then
        echo "  FAIL: console.log detecte dans les fichiers modifies" >&2
        FAILED=1
      else
        echo "  OK: pas de console.log" >&2
      fi
      ;;
    "no_env_secrets")
      # Verifier qu'aucun fichier .env n'est staged
      if git diff --cached --name-only 2>/dev/null | grep -q "\.env$"; then
        echo "  FAIL: fichier .env dans les fichiers stages !" >&2
        FAILED=1
      else
        echo "  OK: pas de .env expose" >&2
      fi
      ;;
    "no_api_keys")
      # Scanner les patterns de cles API courantes
      PATTERNS="sk-[a-zA-Z0-9]{20,}|shpat_[a-f0-9]{32}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16}"
      if git diff --cached 2>/dev/null | grep -qP "$PATTERNS"; then
        echo "  FAIL: cle API detectee dans le diff !" >&2
        FAILED=1
      else
        echo "  OK: pas de cle API en clair" >&2
      fi
      ;;
    "no_todo")
      # Verifier qu'il n'y a pas de TODO dans les fichiers modifies
      if git diff --cached --name-only 2>/dev/null | xargs grep -l "TODO\|FIXME\|HACK" 2>/dev/null | head -1 | grep -q .; then
        echo "  WARN: TODO/FIXME detecte (non bloquant)" >&2
      else
        echo "  OK: pas de TODO" >&2
      fi
      ;;
    *)
      echo "  SKIP: check inconnu '$check'" >&2
      ;;
  esac
done <<< "$CHECKS"

if [ "$FAILED" -ne 0 ]; then
  echo "Quality Gate: ECHEC — corrigez les problemes ci-dessus" >&2
  exit 2
fi

echo "Quality Gate: OK" >&2
exit 0
