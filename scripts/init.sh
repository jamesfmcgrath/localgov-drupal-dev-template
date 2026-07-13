#!/usr/bin/env bash
# One-time template initialiser. Run from the repo root immediately after
# creating a repo from this template:  ./scripts/init.sh
# Prompts for project values, substitutes {{TOKENS}} across all files, then
# removes itself and TEMPLATE.md. Portable across macOS (BSD) and Linux (GNU).
set -euo pipefail

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RESET="\033[0m"
info()  { echo -e "${BOLD}> $*${RESET}"; }
ok()    { echo -e "${GREEN}OK $*${RESET}"; }
warn()  { echo -e "${YELLOW}!! $*${RESET}"; }

# Files that may contain tokens.
FILES=(CLAUDE.md .cursorrules agr.toml README.md TEMPLATE.md .gitignore \
  scripts/setup.sh .claude/settings.local.json.dist)

if ! grep -q "{{MODULE_NAME}}" CLAUDE.md 2>/dev/null; then
  warn "Already initialised (no {{MODULE_NAME}} token in CLAUDE.md). Aborting."
  exit 1
fi

ask() { # ask <prompt> <default> -> echoes answer
  local prompt="$1" def="${2:-}" ans
  if [ -n "$def" ]; then read -r -p "$prompt [$def]: " ans; echo "${ans:-$def}"
  else read -r -p "$prompt: " ans; echo "$ans"; fi
}

echo ""; info "Initialise this template"; echo ""
MODULE_NAME="$(ask 'Module machine name (e.g. localgov_bus_data)' '')"
[ -n "$MODULE_NAME" ] || { warn "Module name is required."; exit 1; }
DEF_LABEL="$(echo "$MODULE_NAME" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1))substr($i,2)}1')"
MODULE_LABEL="$(ask 'Module label' "$DEF_LABEL")"
MODULE_PATH="$(ask 'Module path' "web/modules/custom/$MODULE_NAME")"
MODULE_REPO="$(ask 'Module git URL (blank to skip cloning)' '')"
DEF_DDEV="$(echo "$MODULE_NAME" | tr '_' '-')-dev"
DDEV_NAME="$(ask 'DDEV project name' "$DEF_DDEV")"
DDEV_URL="$(ask 'DDEV site URL' "https://$DDEV_NAME.ddev.site")"
CLIENT="$(ask 'Client / context' 'a local council')"
SKILL_FORK="$(ask 'drupal-agent-resources fork owner (hosts drupal-localgov)' 'jamesfmcgrath')"

echo ""; info "Applying..."
sub() { # sub <token> <value>
  local token="$1" value="$2" f tmp
  for f in "${FILES[@]}"; do
    [ -f "$f" ] || continue
    tmp="$(mktemp)"
    sed "s|{{$token}}|$value|g" "$f" > "$tmp" && mv "$tmp" "$f"
  done
}
# Order matters: MODULE_PATH/DDEV_URL defaults may embed other tokens, but we
# captured them as literal strings above, so plain substitution is safe.
sub MODULE_NAME  "$MODULE_NAME"
sub MODULE_LABEL "$MODULE_LABEL"
sub MODULE_PATH  "$MODULE_PATH"
sub MODULE_REPO  "$MODULE_REPO"
sub DDEV_NAME    "$DDEV_NAME"
sub DDEV_URL     "$DDEV_URL"
sub CLIENT       "$CLIENT"
sub SKILL_FORK   "$SKILL_FORK"

# Remove template-only artifacts.
rm -f TEMPLATE.md
ok "Tokens applied."
info "Removing initialiser (scripts/init.sh)..."
rm -f scripts/init.sh
ok "Done. Next: ./scripts/setup.sh  then  ddev start"
echo ""
warn "Review the git diff, then commit: git add -A && git commit -m 'Initialise from template'"
