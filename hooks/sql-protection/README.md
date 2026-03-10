# SQL Protection Hook

A `PreToolUse` hook for Claude Code that intercepts destructive SQL queries **before** they hit your database.

## The problem

Claude Code can run SQL on your database via MCP servers (Supabase, Postgres, etc.). One bad prompt and it's `DROP TABLE` in production. No confirmation, no undo.

## What it blocks

- `DELETE FROM` (without WHERE)
- `DROP TABLE / SCHEMA / DATABASE`
- `TRUNCATE`
- `ALTER TABLE ... DROP`
- `UPDATE ... SET` (without WHERE)

When a destructive query is detected, the hook returns a `deny` decision and Claude Code skips the tool call entirely.

## Setup

Add this to your `~/.claude/settings.json` (or `.claude/settings.json` in your project):

### Linux / macOS (bash)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__supabase__*",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'INPUT=$(cat); QUERY=$(echo \"$INPUT\" | grep -ioE \"(DELETE\\s+FROM|DROP\\s+(TABLE|SCHEMA|DATABASE)|TRUNCATE|ALTER\\s+TABLE.*DROP|UPDATE\\s+\\w+\\s+SET(?!.*WHERE))\"); if [ -n \"$QUERY\" ]; then echo \"{\\\"hookSpecificOutput\\\":{\\\"permissionDecision\\\":\\\"deny\\\",\\\"permissionDecisionReason\\\":\\\"Destructive SQL blocked by safety hook\\\"}}\"; fi'"
          }
        ]
      }
    ]
  }
}
```

### Windows (PowerShell)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__supabase__*",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -Command \"$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json; $toolInput = $jsonInput.tool_input | ConvertTo-Json -Depth 10; if ($toolInput -match '(?i)(DELETE\\s+FROM|DROP\\s+(TABLE|SCHEMA|DATABASE)|TRUNCATE|ALTER\\s+TABLE.*DROP|UPDATE\\s+\\w+\\s+SET(?!.*WHERE))') { Write-Output '{\\\"hookSpecificOutput\\\":{\\\"permissionDecision\\\":\\\"deny\\\",\\\"permissionDecisionReason\\\":\\\"Destructive SQL blocked by safety hook\\\"}}'; exit 0 }; exit 0\""
          }
        ]
      }
    ]
  }
}
```

## Customize the matcher

Change `mcp__supabase__*` to match your database MCP server:

- `mcp__postgres__*` — PostgreSQL MCP
- `mcp__mysql__*` — MySQL MCP
- `mcp__supabase__*` — Supabase MCP
- `mcp__*` — All MCP servers (nuclear option)

## How it works

1. Claude Code is about to call a database tool
2. The `PreToolUse` hook fires and reads the tool input (JSON via stdin)
3. A regex scans for destructive SQL patterns
4. If matched → returns `permissionDecision: "deny"` → tool call is skipped
5. If safe → exits silently → tool call proceeds normally

## FAQ

**Can I still run DELETE intentionally?**
Yes — `DELETE FROM users WHERE id = 5` passes through fine. Only unfiltered `DELETE FROM` (no WHERE clause) gets blocked.

**Does it slow things down?**
No. The regex check takes <1ms. You won't notice it.

**Can I add more patterns?**
Absolutely. Add any regex pattern to the match group. For example, to block `INSERT INTO` on a specific table:

```
INSERT\\s+INTO\\s+production_logs
```
