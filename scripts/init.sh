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

if ! grep -q "{{MODULE_INTRO}}" AGENTS.md 2>/dev/null; then
  warn "Already initialised (no {{MODULE_INTRO}} token in AGENTS.md). Aborting."
  exit 1
fi

ask() { # ask <prompt> <default> -> echoes answer
  local prompt="$1" def="${2:-}" ans
  if [ -n "$def" ]; then read -r -p "$prompt [$def]: " ans; echo "${ans:-$def}"
  else read -r -p "$prompt: " ans; echo "$ans"; fi
}

titlecase() { echo "$1" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1))substr($i,2)}1'; }

ask_machine_name() { # ask_machine_name <prompt> -> echoes a valid name or empty
  local prompt="$1" ans
  while true; do
    ans="$(ask "$prompt" '')"
    [ -z "$ans" ] && { echo ""; return 0; }
    case "$ans" in
      [a-z]*) ;;
      *) warn "Machine names must start with a lowercase letter." >&2; continue ;;
    esac
    if [ -z "$(printf '%s' "$ans" | tr -d 'a-z0-9_')" ]; then
      echo "$ans"; return 0
    fi
    warn "Machine names may contain only lowercase letters, digits and underscores (for example my_module). Hyphens are not valid." >&2
  done
}

echo ""; info "Initialise this template"; echo ""
MODULE_NAME="$(ask_machine_name 'Module machine name (blank for a site-only project)')"

if [ -n "$MODULE_NAME" ]; then
  MODULE_LABEL="$(ask 'Module label' "$(titlecase "$MODULE_NAME")")"
  MODULE_PATH="$(ask 'Module path' "web/modules/custom/$MODULE_NAME")"
  MODULE_REPO="$(ask 'Module git URL (blank to skip cloning)' '')"
else
  MODULE_LABEL=""
  MODULE_PATH="web/modules/custom"
  MODULE_REPO=""
fi

# Optional custom theme. Module and theme are independent: all four
# combinations (module only, theme only, both, neither) are supported.
THEME_NAME="$(ask_machine_name 'Theme machine name (blank for no custom theme)')"
if [ -n "$THEME_NAME" ]; then
  THEME_LABEL="$(ask 'Theme label' "$(titlecase "$THEME_NAME")")"
  THEME_PATH="web/themes/custom/$THEME_NAME"
else
  THEME_LABEL=""
  THEME_PATH="web/themes/custom"
fi

if [ -n "$MODULE_NAME" ]; then
  DEF_DDEV="$(echo "$MODULE_NAME" | tr '_' '-')-dev"
elif [ -n "$THEME_NAME" ]; then
  DEF_DDEV="$(echo "$THEME_NAME" | tr '_' '-')-dev"
else
  DEF_DDEV="site-dev"
fi
DDEV_NAME="$(ask 'DDEV project name' "$DEF_DDEV")"
DDEV_URL="$(ask 'DDEV site URL' "https://$DDEV_NAME.ddev.site")"
CLIENT="$(ask 'Client / context' 'a local council')"
SKILL_FORK="$(ask 'drupal-agent-resources fork owner (hosts drupal-localgov)' 'jamesfmcgrath')"

echo ""
FLAVOUR="$(ask 'Drupal flavour: localgov, vanilla or cms' 'localgov')"
VERSION="$(ask 'Drupal major version: 11 or 10' '11')"

case "$VERSION" in 10) DRUPAL_TYPE="drupal10";; *) DRUPAL_TYPE="drupal11"; VERSION="11";; esac
case "$FLAVOUR" in
  vanilla|drupal)
    DRUPAL_FLAVOUR="vanilla"
    INSTALL_PROFILE="standard"
    COMPOSER_PROJECT="drupal/recommended-project:^${VERSION}"
    ;;
  cms)
    DRUPAL_FLAVOUR="cms"
    # Drupal CMS is Drupal 11 only; force version regardless of the answer.
    if [ "$VERSION" = "10" ]; then
      warn "Drupal CMS is Drupal 11 only; using Drupal 11."
    fi
    VERSION="11"; DRUPAL_TYPE="drupal11"
    INSTALL_PROFILE="recipes/drupal_cms_starter"
    COMPOSER_PROJECT="drupal/cms"
    ;;
  *)
    DRUPAL_FLAVOUR="localgov"
    INSTALL_PROFILE="localgov"
    # LocalGov distribution: 4.x = Drupal 11, 3.x = Drupal 10. Verify the
    # localgov_project template tag if a clean create fails.
    if [ "$VERSION" = "10" ]; then
      COMPOSER_PROJECT="drupal/localgov_project:^3.0"
    else
      COMPOSER_PROJECT="drupal/localgov_project"
    fi
    ;;
esac

# Prose fragments that read naturally in all four module/theme combinations.
if [ -n "$MODULE_NAME" ]; then
  MODULE_INTRO=", the \`$MODULE_NAME\` module for $CLIENT"
  MODULE_LINE="\`$MODULE_PATH/\`"
  PACKAGE_NAME="${MODULE_NAME}-dev"
  PACKAGE_DESCRIPTION="Front-end tooling for $MODULE_NAME ($CLIENT)."
elif [ -n "$THEME_NAME" ]; then
  MODULE_INTRO=" for $CLIENT"
  MODULE_LINE="none yet, theme-only project"
  PACKAGE_NAME="${THEME_NAME}-dev"
  PACKAGE_DESCRIPTION="Front-end tooling for $THEME_NAME ($CLIENT)."
else
  MODULE_INTRO=" for $CLIENT"
  MODULE_LINE="none yet, site-only project"
  PACKAGE_NAME="$DDEV_NAME"
  PACKAGE_DESCRIPTION="Front-end tooling for $CLIENT."
fi

if [ -n "$THEME_NAME" ]; then
  THEME_INTRO=", themed by \`$THEME_NAME\`"
  THEME_LINE="\`$THEME_PATH/\` (\`$THEME_NAME\`)"
  THEME_LAYER=" Theme-layer fixes belong in \`$THEME_PATH/\`."
else
  THEME_INTRO=""
  THEME_LINE="none yet, no custom theme"
  THEME_LAYER=""
fi

if [ -n "$MODULE_NAME" ] && [ -n "$THEME_NAME" ]; then
  MODULE_AFFECTS="the \`$MODULE_NAME\` module and \`$THEME_NAME\` theme affect"
elif [ -n "$MODULE_NAME" ]; then
  MODULE_AFFECTS="the \`$MODULE_NAME\` module affects"
elif [ -n "$THEME_NAME" ]; then
  MODULE_AFFECTS="the \`$THEME_NAME\` theme affects"
else
  MODULE_AFFECTS="the site includes"
fi

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
sub MODULE_NAME         "$MODULE_NAME"
sub MODULE_LABEL        "$MODULE_LABEL"
sub MODULE_PATH         "$MODULE_PATH"
sub MODULE_REPO         "$MODULE_REPO"
sub MODULE_INTRO        "$MODULE_INTRO"
sub MODULE_LINE         "$MODULE_LINE"
sub MODULE_AFFECTS      "$MODULE_AFFECTS"
sub THEME_NAME          "$THEME_NAME"
sub THEME_LABEL         "$THEME_LABEL"
sub THEME_PATH          "$THEME_PATH"
sub THEME_INTRO         "$THEME_INTRO"
sub THEME_LINE          "$THEME_LINE"
sub THEME_LAYER         "$THEME_LAYER"
sub PACKAGE_NAME        "$PACKAGE_NAME"
sub PACKAGE_DESCRIPTION "$PACKAGE_DESCRIPTION"
sub DDEV_NAME           "$DDEV_NAME"
sub DDEV_URL         "$DDEV_URL"
sub CLIENT           "$CLIENT"
sub SKILL_FORK       "$SKILL_FORK"
sub DRUPAL_TYPE      "$DRUPAL_TYPE"
sub DRUPAL_FLAVOUR   "$DRUPAL_FLAVOUR"
sub INSTALL_PROFILE  "$INSTALL_PROFILE"
sub COMPOSER_PROJECT "$COMPOSER_PROJECT"

rm -f TEMPLATE.md scripts/test-template.sh
chmod +x scripts/setup.sh scripts/install-drupal 2>/dev/null || true
if [ -n "$MODULE_NAME" ] && [ -n "$THEME_NAME" ]; then
  SCOPE="module $MODULE_NAME, theme $THEME_NAME"
elif [ -n "$MODULE_NAME" ]; then
  SCOPE="module $MODULE_NAME"
elif [ -n "$THEME_NAME" ]; then
  SCOPE="theme $THEME_NAME"
else
  SCOPE="site-only"
fi
ok "Tokens applied ($FLAVOUR, Drupal $VERSION, $SCOPE)."
info "Removing initialiser (scripts/init.sh)..."
rm -f scripts/init.sh
ok "Done. Next: ./scripts/setup.sh"
echo ""
if [ -z "$MODULE_NAME" ]; then
  warn "No module configured: to add one later, create it under web/modules/custom/ and set MODULE and MODULE_NAME in the Makefile."
fi
if [ -n "$THEME_NAME" ]; then
  warn "Theme $THEME_NAME is configured but not scaffolded yet. After ./scripts/setup.sh, run: make subtheme"
else
  warn "No theme configured: to add one later, create it under web/themes/custom/ and set THEME_NAME, THEME_LABEL, and THEME_PATH in the Makefile."
fi
warn "Review the git diff, then commit: git add -A && git commit -m 'Initialise from template'"
