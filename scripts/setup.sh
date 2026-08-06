#!/usr/bin/env bash
# {{DDEV_NAME}} - one-command dev environment spin-up.
# Run from the repo root: ./scripts/setup.sh
# Flags:
#   --force-reviewer   re-fetch drupal-reviewer even if present
#   --skip-install     scaffold + tooling only, do not install the Drupal site
set -euo pipefail

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
info()    { echo -e "${BOLD}> $*${RESET}"; }
success() { echo -e "${GREEN}OK $*${RESET}"; }
warn()    { echo -e "${YELLOW}!! $*${RESET}"; }
error()   { echo -e "${RED}xx $*${RESET}"; exit 1; }

MODULE_REPO="{{MODULE_REPO}}"
MODULE_PATH="{{MODULE_PATH}}"
MODULE_NAME="{{MODULE_NAME}}"
SKILL_FORK="{{SKILL_FORK}}"
COMPOSER_PROJECT="{{COMPOSER_PROJECT}}"
INSTALL_PROFILE="{{INSTALL_PROFILE}}"
REVIEWER_REF="main"
REVIEWER_URL="https://raw.githubusercontent.com/${SKILL_FORK}/drupal-agent-resources/${REVIEWER_REF}/.claude/agents/drupal-reviewer.md"

FORCE_REVIEWER=0; SKIP_INSTALL=0
for a in "$@"; do
  case "$a" in
    --force-reviewer) FORCE_REVIEWER=1 ;;
    --skip-install)   SKIP_INSTALL=1 ;;
  esac
done

echo ""; echo -e "${BOLD}=== {{DDEV_NAME}} setup ===${RESET}"; echo ""

# --- Prerequisites ---
info "Checking prerequisites..."
command -v ddev &>/dev/null || error "DDEV not found. Install from https://ddev.com then re-run."
command -v git  &>/dev/null || error "git not found."
success "DDEV: $(ddev version | head -1)"

# --- Agent resources (skills) ---
info "Installing Claude Code / Cursor skills via agr..."
if command -v agr &>/dev/null; then
  if [ -f "agr.lock" ]; then
    agr sync && success "Skills installed from agr.lock (agr sync)."
  else
    agr add madsnorgaard/drupal-agent-resources/drupal-expert --overwrite
    agr add madsnorgaard/drupal-agent-resources/ddev-expert --overwrite
    agr add "${SKILL_FORK}/drupal-agent-resources/drupal-localgov" --overwrite
    success "Skills installed (drupal-expert, ddev-expert, drupal-localgov)."
  fi
else
  warn "agr not found, skipping skills."
  warn "Install uv (https://docs.astral.sh/uv/), then: uv tool install agr && agr sync"
fi

# --- drupal-reviewer agent (tracked copy is canonical) ---
info "Ensuring drupal-reviewer agent..."
mkdir -p .claude/agents
if [ -f ".claude/agents/drupal-reviewer.md" ] && [ "$FORCE_REVIEWER" -eq 0 ]; then
  success "drupal-reviewer already present (tracked copy kept)."
elif command -v curl &>/dev/null; then
  curl -fsSL -o .claude/agents/drupal-reviewer.md "${REVIEWER_URL}" \
    && success "drupal-reviewer fetched (${REVIEWER_REF})." \
    || warn "Could not fetch drupal-reviewer. Save manually from ${REVIEWER_URL}"
else
  warn "curl not found. Save drupal-reviewer manually from ${REVIEWER_URL}"
fi

# --- Claude settings.local.json ---
if [ ! -f ".claude/settings.local.json" ] && [ -f ".claude/settings.local.json.dist" ]; then
  info "Creating .claude/settings.local.json from dist..."
  sed "s|<absolute-path-to-repo>|$(pwd)|g" .claude/settings.local.json.dist > .claude/settings.local.json
  success ".claude/settings.local.json created."
fi

# --- DDEV ---
info "Starting DDEV..."
ddev start
success "DDEV running."

# --- Drupal codebase (scaffold without clobbering template files) ---
if [ ! -f "composer.json" ]; then
  info "Scaffolding Drupal project: ${COMPOSER_PROJECT}"
  ddev exec "rm -rf /tmp/scaffold && composer create-project ${COMPOSER_PROJECT} /tmp/scaffold --no-install --no-interaction"
  # cp -n preserves the template's own files (CLAUDE.md, Makefile, scripts, etc.).
  ddev exec "cp -rn /tmp/scaffold/. /var/www/html/ && rm -rf /tmp/scaffold"
  success "Project scaffolded."
fi
info "Installing Composer dependencies..."
ddev composer install
success "Dependencies installed."

# --- Custom code workspace ---
# The quality tooling (LINT_PATHS in the Makefile, phpcs.xml.dist, phpstan.neon,
# and CI) scopes to these paths. Create them up front so a bare phpcs or phpstan
# run works on a project that has only modules, or only a theme, so far.
mkdir -p web/modules/custom web/themes/custom

# --- Dev tooling (lint / static analysis / tests) ---
info "Adding PHP dev tooling..."
# Pre-authorise the Composer plugins the dev tooling pulls in, so the require
# below is not aborted by a project's allow-plugins allowlist. Drupal CMS ships
# a stricter allowlist than the localgov and vanilla project templates, so
# phpstan/extension-installer (via mglaman/phpstan-drupal) and the phpcodesniffer
# installer (via drupal/coder) must be allowed first.
ddev composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true 2>/dev/null || true
ddev composer config --no-plugins allow-plugins.phpstan/extension-installer true 2>/dev/null || true
if ddev composer require --dev --no-interaction -W \
  drupal/core-dev drupal/coder mglaman/phpstan-drupal \
  phpstan/phpstan phpstan/phpstan-deprecation-rules \
  vincentlanglet/twig-cs-fixer drush/drush; then
  success "PHP dev tooling installed."
else
  warn "Some dev dependencies failed to install; add them manually."
fi

# --- Prettier ---
if [ -f "package.json" ]; then
  info "Installing Prettier (npm)..."
  ddev exec "npm install" && success "Prettier installed." || warn "npm install failed; run 'ddev exec npm install' later."
fi

# --- Optional: clone the target module ---
if [ -n "${MODULE_NAME}" ]; then
  if [ -n "${MODULE_REPO}" ] && [ ! -d "${MODULE_PATH}" ]; then
    info "Cloning module into ${MODULE_PATH}..."
    mkdir -p "$(dirname "${MODULE_PATH}")"
    git clone "${MODULE_REPO}" "${MODULE_PATH}" && success "Module cloned." || warn "Module clone failed; clone manually."
  fi
else
  info "Site-only project: skipping module clone and enable."
fi

# --- Install the site ---
if [ "$SKIP_INSTALL" -eq 0 ]; then
  info "Installing Drupal (profile: ${INSTALL_PROFILE})..."
  ./scripts/install-drupal "${INSTALL_PROFILE}"
  if [ -n "${MODULE_NAME}" ] && [ -d "${MODULE_PATH}" ]; then
    info "Enabling ${MODULE_NAME}..."
    ddev drush en "${MODULE_NAME}" -y && ddev drush cr && success "${MODULE_NAME} enabled."
  fi
else
  warn "--skip-install set: site not installed. Run ./scripts/install-drupal when ready."
fi

echo ""; success "Setup complete."
echo "  Site:  ${BOLD}{{DDEV_URL}}${RESET}"
echo "  Open:  ddev launch        Login: ddev drush uli"
echo "  Tasks: make help"
