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
FILES=(AGENTS.md agr.toml README.md TEMPLATE.md .gitignore Makefile \
  scripts/setup.sh .claude/settings.local.json.dist .claude/commands/a11y-check.md \
  .ddev/config.yaml phpcs.xml.dist phpstan.neon package.json .github/workflows/ci.yml)

if ! grep -q "{{MODULE_NAME}}" AGENTS.md 2>/dev/null; then
  warn "Already initialised (no {{MODULE_NAME}} token in AGENTS.md). Aborting."
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

echo ""
FLAVOUR="$(ask 'Drupal flavour: localgov or vanilla' 'localgov')"
VERSION="$(ask 'Drupal major version: 11 or 10' '11')"

case "$VERSION" in 10) DRUPAL_TYPE="drupal10";; *) DRUPAL_TYPE="drupal11"; VERSION="11";; esac
case "$FLAVOUR" in
  vanilla|drupal)
    INSTALL_PROFILE="standard"
    COMPOSER_PROJECT="drupal/recommended-project:^${VERSION}"
    ;;
  *)
    INSTALL_PROFILE="localgov"
    # LocalGov distribution: 4.x = Drupal 11, 3.x = Drupal 10. Verify the
    # localgov-project template tag if a clean create fails.
    if [ "$VERSION" = "10" ]; then
      COMPOSER_PROJECT="localgovdrupal/localgov-project:^3.0"
    else
      COMPOSER_PROJECT="localgovdrupal/localgov-project"
    fi
    ;;
esac

echo ""; info "Applying..."
sub() { # sub <token> <value>
  local token="$1" value="$2" f tmp
  for f in "${FILES[@]}"; do
    [ -f "$f" ] || continue
    tmp="$(mktemp)"
    # Write back into the original file so its permissions (e.g. +x) are kept.
    sed "s|{{$token}}|$value|g" "$f" > "$tmp" && cat "$tmp" > "$f" && rm -f "$tmp"
  done
}
sub MODULE_NAME      "$MODULE_NAME"
sub MODULE_LABEL     "$MODULE_LABEL"
sub MODULE_PATH      "$MODULE_PATH"
sub MODULE_REPO      "$MODULE_REPO"
sub DDEV_NAME        "$DDEV_NAME"
sub DDEV_URL         "$DDEV_URL"
sub CLIENT           "$CLIENT"
sub SKILL_FORK       "$SKILL_FORK"
sub DRUPAL_TYPE      "$DRUPAL_TYPE"
sub INSTALL_PROFILE  "$INSTALL_PROFILE"
sub COMPOSER_PROJECT "$COMPOSER_PROJECT"

rm -f TEMPLATE.md
chmod +x scripts/setup.sh scripts/install-drupal 2>/dev/null || true
ok "Tokens applied ($FLAVOUR, Drupal $VERSION)."
info "Removing initialiser (scripts/init.sh)..."
rm -f scripts/init.sh
ok "Done. Next: ./scripts/setup.sh"
echo ""
warn "Review the git diff, then commit: git add -A && git commit -m 'Initialise from template'"
