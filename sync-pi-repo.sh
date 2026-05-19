#!/usr/bin/env zsh
# sync-pi-repo.sh — Copy ~/.pi/agent/ into the repo (local is source of truth)
# Excludes: auth.json, sessions/, git/, themes/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_PI="$HOME/.pi/agent"
REPO_PI="$SCRIPT_DIR/pi/agent"

if [[ ! -d "$HOME_PI" ]]; then
  echo "❌  ~/.pi/agent/ not found. Nothing to sync."
  exit 1
fi

# Ensure repo directory exists
mkdir -p "$REPO_PI"

# Files/dirs to exclude
EXCLUDES=(
  "auth.json"
  "sessions"
  "git"
  "themes"
)

count=0

while IFS= read -r -d '' file; do
  rel="${file#$HOME_PI/}"

  # Check if any excluded path is a prefix of this file
  skip=false
  for excl in "${EXCLUDES[@]}"; do
    if [[ "$rel" == "$excl" || "$rel" == "$excl/"* ]]; then
      skip=true
      break
    fi
  done

  if $skip; then
    continue
  fi

  dest="$REPO_PI/$rel"
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]]; then
    cp -f "$file" "$dest"
    echo "  ✏️  $rel"
  else
    cp -f "$file" "$dest"
    echo "  🆕  $rel"
  fi
  count=$((count + 1))
done < <(find "$HOME_PI" -type f -print0)

echo ""
echo "✅ Synced $count files from ~/.pi/agent/ → repo"
