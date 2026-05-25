# pi Agent Config

Configuration for [pi-coding-agent](https://github.com/mariozechner/pi-coding-agent), a terminal-based AI coding agent. See the [main README](../README.md) for the local LLM setup this config is paired with.

## Structure

```
agent/
├── AGENTS.md               # Agent behavior rules and shell aliases
├── models.json             # Model providers
├── settings.json           # UI settings and default model
├── extensions/
│   ├── context-pruner.ts   # Truncates oversized tool outputs, warns at 70% context
│   ├── key-rotator/        # Rotates through multiple NVIDIA API keys
│   ├── permission-gate.ts  # Confirms before dangerous bash commands (rm, sudo, chmod 777)
│   └── session-name.ts     # /session-name to name sessions for the session picker
├── skills/
│   └── plan-first/
│       └── SKILL.md        # Forces TODO.md planning before code changes
└── themes/
    └── nord-cachy.json     # Nord-inspired theme
```

## Models

The repo copy has sanitized API keys — add real keys locally.

| Provider | Model | Notes |
|---|---|---|
| llamacpp | qwen-local (Qwen3.6-35B-A3B) | Default. Local via `llama-server` at `127.0.0.1:8085`. 32k context. |
| nvidia | minimaxai/minimax-m2.7 | Requires NVIDIA API key(s). Rate-limit distributed by key-rotator. |
| gemini-studio | gemma-4-31b-it | Google Generative AI API. Vision support. |


## Extensions

### key-rotator

Rotates through multiple NVIDIA API keys to distribute rate limits across free-tier accounts.

```bash
mkdir -p ~/.pi/agent/extensions/key-rotator
# Add your keys:
$EDITOR ~/.pi/agent/extensions/key-rotator/keys.json
```

```json
{
  "keys": ["nvapi-...", "nvapi-...", "nvapi-...", "nvapi-...", "nvapi-..."],
  "currentIndex": 0
}
```

After editing, restart pi. Use `/keys` to check rotation status.

### context-pruner

- Truncates `read` outputs beyond ~8k tokens
- Truncates `bash` outputs beyond ~4k tokens
- Warns once per session when context hits 70% (~22.9k tokens)
- Aborts the turn once per session when context hits 85% (~27.9k tokens)

### permission-gate

Prompts for confirmation before running: `rm`, `sudo`, `chmod`/`chown 777`, `truncate`. Blocked without a UI.

### session-name

Use `/session-name [name]` to give the current session a friendly name visible in the session picker.

## Settings
Configured in `agent/settings.json`.

- **Default provider:** `llamacpp` (local Qwen3.6-35B-A3B)
- **Compaction:** enabled — reserves 8192 tokens, keeps 16k recent tokens on compact
- **Shell:** `/usr/bin/zsh`

## Syncing

Copies `~/.pi/agent/` → `pi/agent/` (from the repo root). These are excluded automatically:

- `auth.json`, `sessions/`, `git/`, `themes/`,`npm/`, `node_modules/`, and `extensions/key-rotator/keys.json`

API keys in `models.json` are redacted during sync.

```bash
./sync-pi-repo.sh --dry-run  # preview changes
./sync-pi-repo.sh            # actually sync
```
