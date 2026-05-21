#!/usr/bin/env zsh
# sync-pi-repo.sh — Copy ~/.pi/agent/ into the repo (home is source of truth)
# Direction: ~/.pi/agent -> ~/dev/local-llm-setup/pi/agent

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_PI="$HOME/.pi/agent"
REPO_PI="$SCRIPT_DIR/pi/agent"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=true
fi

if [[ ! -d "$HOME_PI" ]]; then
  echo "ERROR: ~/.pi/agent/ not found. Nothing to sync."
  exit 1
fi

mkdir -p "$REPO_PI"

# Secrets + churn to keep local-only
EXCLUDES=(
  "auth.json"
  "sessions"
  "git"
  "themes"
  "npm"
  "node_modules"
  "extensions/key-rotator/keys.json"
)

SYNC_FLAGS=(-a --delete)
if $DRY_RUN; then
  SYNC_FLAGS+=(--dry-run --itemize-changes --human-readable)
fi

RSYNC_ARGS=()
for excl in "${EXCLUDES[@]}"; do
  RSYNC_ARGS+=(--exclude "$excl")
done

RSYNC_OUTPUT="$(rsync "${SYNC_FLAGS[@]}" "${RSYNC_ARGS[@]}" "$HOME_PI/" "$REPO_PI/")"

if [[ -n "$RSYNC_OUTPUT" ]]; then
  printf "%s\n" "$RSYNC_OUTPUT"
elif $DRY_RUN; then
  echo "No changes: repo already matches ~/.pi/agent/ (after excludes)."
fi

REPO_MODELS="$REPO_PI/models.json"
if [[ -f "$REPO_MODELS" ]]; then
  if command -v jq >/dev/null 2>&1; then
    if $DRY_RUN; then
      echo "Would redact apiKey fields in $REPO_MODELS"
    else
      TMP_MODELS="$(mktemp)"
      jq '
        if (.providers? | type == "object") then
          .providers |= with_entries(
            if (.value.apiKey? != null) then
              .value.apiKey = (
                if .value.apiKey == "local" then
                  "local"
                else
                  (.key + "-api-key-placeholder")
                end
              )
            else
              .
            end
          )
        else
          .
        end
      ' "$REPO_MODELS" > "$TMP_MODELS"
      mv "$TMP_MODELS" "$REPO_MODELS"
      echo "Redacted apiKey fields in $REPO_MODELS"
    fi
  else
    echo "WARN: jq not found; could not redact apiKey fields in $REPO_MODELS"
  fi
fi

echo ""
if $DRY_RUN; then
  echo "Dry run complete: ~/.pi/agent/ -> repo"
else
  echo "Synced ~/.pi/agent/ -> repo"
fi
