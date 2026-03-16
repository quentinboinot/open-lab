# Claude Code Armor

6 security & productivity hooks for Claude Code. Install in one line.

> Stop coding naked. Ship with armor.

## What's inside

| Hook | Event | What it does |
|------|-------|-------------|
| **SQL Shield** | PreToolUse | Blocks destructive SQL (DROP, TRUNCATE, DELETE without WHERE) |
| **MCP Rate Guard** | PreToolUse | Rate limits any MCP tool call (configurable per tool) |
| **MCP Logger** | PostToolUse | Logs every MCP call to JSONL with daily rotation |
| **Quality Gate** | TaskCompleted | Runs your custom checklist before closing a task |
| **Docker Boot** | SessionStart | Auto-starts your MCP containers when you open Claude Code |
| **Ping Stop** | Stop | Sends a notification (Telegram, ntfy, webhook) when session ends |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/quentinboinot/open-lab/main/claude-code-armor/install.sh | bash
```

This downloads the 6 hooks to `~/.claude/hooks/armor/` and creates a default config at `~/.cc-armor.json`.

## Setup

After installing, add the hooks to your Claude Code `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__supabase__execute_sql",
        "command": "bash ~/.claude/hooks/armor/sql-shield.sh"
      },
      {
        "matcher": "mcp__*",
        "command": "CLAUDE_TOOL_NAME=$CLAUDE_TOOL_NAME bash ~/.claude/hooks/armor/mcp-rate-guard.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "mcp__*",
        "command": "CLAUDE_TOOL_NAME=$CLAUDE_TOOL_NAME bash ~/.claude/hooks/armor/mcp-logger.sh"
      }
    ],
    "TaskCompleted": [
      {
        "command": "bash ~/.claude/hooks/armor/quality-gate.sh"
      }
    ],
    "SessionStart": [
      {
        "command": "bash ~/.claude/hooks/armor/docker-boot.sh"
      }
    ],
    "Stop": [
      {
        "command": "bash ~/.claude/hooks/armor/ping-stop.sh"
      }
    ]
  }
}
```

## Configure

Edit `~/.cc-armor.json` to customize:

```json
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
    "containers": ["mcp-chrome", "mcp-playwright"]
  },
  "ping_stop": {
    "enabled": true,
    "method": "ntfy",
    "url": "https://ntfy.sh/my-claude-code"
  }
}
```

### Ping Stop methods

| Method | Setup | Cost |
|--------|-------|------|
| **ntfy.sh** | Just pick a topic name. No account needed. | Free |
| **Telegram** | Create a bot via @BotFather, get your chat_id | Free |
| **Webhook** | Any URL that accepts POST | Depends |

### Quality Gate checks

| Check | What it catches |
|-------|----------------|
| `no_console_log` | console.log left in staged files |
| `no_env_secrets` | .env files about to be committed |
| `no_api_keys` | API keys (sk-*, shpat_*, ghp_*, AKIA*) in diff |
| `no_todo` | TODO/FIXME/HACK comments (warning, non-blocking) |

## Each hook is independent

Don't want all 6? Pick what you need. Each `.sh` file works standalone.

## Requirements

- Claude Code CLI
- bash 4+
- `jq` (for Rate Guard, Quality Gate, Docker Boot, Ping Stop)
- `docker` (for Docker Boot only)
- `curl` (for Ping Stop only)

## License

MIT — do whatever you want.

---

**Drop #2** from [open-lab](https://quentinboinot.github.io/open-lab/) by [@quentinboinot](https://github.com/quentinboinot)

*Built with [Claude Code](https://claude.ai/claude-code).*
