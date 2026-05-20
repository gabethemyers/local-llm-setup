# Pi Coding Agent Setup

Configuration for [pi-coding-agent](https://github.com/mariozechner/pi-coding-agent), a terminal-based AI coding agent.

## Structure

```
agent/
├── AGENTS.md           # Agent behavior rules and shell aliases
├── models.json         # Model providers and configuration
├── settings.json       # UI and default model settings
├── extensions/
│   ├── context-pruner.ts   # Truncates oversized tool outputs, warns at 70% context usage
│   └── permission-gate.ts  # Prompts before dangerous bash commands (rm -rf, sudo, chmod 777)
└── skills/
    └── plan-first/
        └── SKILL.md    # Forces TODO.md planning phase before any code changes
```

## Models

| Provider | Model | Notes |
|---|---|---|
| llamacpp | Qwen3-30B-A3B (local) | Served via llama-server at `127.0.0.1:8085` |
| gemini-studio | gemma-4-31b-it | Google Generative AI API |

Default provider is `llamacpp`.

## Setup

1. Place the `agent/` directory where pi expects its config
2. Add your Google API key to `~/.pi/agent/models.json` under `gemini-studio.apiKey` (the repo copy is sanitized by `sync-pi-repo.sh`)
3. Ensure llama-server is running (`ai code`) before using the local model
