#!/bin/bash
# Claude Code Armor — Installation
# Usage: curl -fsSL https://quentinboinot.github.io/open-lab/claude-code-armor/install.sh | bash

set -e

ARMOR_DIR="$HOME/.claude/hooks/armor"
CONFIG_FILE="$HOME/.cc-armor.json"
REPO_URL="https://raw.githubusercontent.com/quentinboinot/open-lab/main/claude-code-armor"

echo ""
echo "  Claude Code Armor — Installation"
echo "  Stop coding naked. Ship with armor."
echo ""

# Creer le dossier
mkdir -p "$ARMOR_DIR"

# Telecharger les 6 hooks
HOOKS=("sql-shield" "mcp-rate-guard" "mcp-logger" "quality-gate" "docker-boot" "ping-stop")

for hook in "${HOOKS[@]}"; do
  echo "  Downloading ${hook}.sh..."
  curl -fsSL "${REPO_URL}/hooks/${hook}.sh" -o "${ARMOR_DIR}/${hook}.sh"
  chmod +x "${ARMOR_DIR}/${hook}.sh"
done

# Creer la config par defaut si elle n'existe pas
if [ ! -f "$CONFIG_FILE" ]; then
  echo "  Creating default config..."
  cat > "$CONFIG_FILE" << 'CONF'
{
  "rate_guard": {
    "rules": {
      "instagram_*": { "max": 30, "window": 3600 },
      "camoufox_*": { "max": 10, "window": 60 }
    }
  },
  "quality_gate": {
    "checks": ["no_console_log", "no_env_secrets", "no_api_keys"]
  },
  "docker_boot": {
    "containers": []
  },
  "ping_stop": {
    "enabled": false,
    "method": "ntfy",
    "url": "https://ntfy.sh/my-claude-code"
  }
}
CONF
fi

echo ""
echo "  Installed 6 hooks in $ARMOR_DIR"
echo "  Config: $CONFIG_FILE"
echo ""
echo "  Next: add hooks to your Claude Code settings.json"
echo "  See: https://github.com/quentinboinot/open-lab/tree/main/claude-code-armor"
echo ""
echo "  Done."
