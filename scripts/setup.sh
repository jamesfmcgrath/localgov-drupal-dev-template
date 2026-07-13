#!/usr/bin/env bash
# {{DDEV_NAME}}, one-shot dev environment setup.
# Run from the repo root: ./scripts/setup.sh
# Re-runnable. Flags: --force-reviewer (re-fetch drupal-reviewer even if present)
set -euo pipefail

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
info()    { echo -e "${BOLD}> $*${RESET}"; }
success() { echo -e "${GREEN}OK $*${RESET}"; }
warn()    { echo -e "${YELLOW}!! $*${RESET}"; }
error()   { echo -e "${RED}xx $*${RESET}"; exit 1; }

MODULE_REPO="{{MODULE_REPO}}"
MODULE_PATH="{{MODULE_PATH}}"
SKILL_FORK="{{SKILL_FORK}}"
# Pin drupal-reviewer to a tag/commit for reproducibility; "main" tracks latest.
REVIEWER_REF="main"
REVIEWER_URL="https://raw.githubusercontent.com/madsnorgaard/drupal-agent-resources/${REVIEWER_REF}/.claude/agents/drupal-reviewer.md"

FORCE_REVIEWER=0
[ "${1:-}" = "--force-reviewer" ] && FORCE_REVIEWER=1

echo ""; echo -e "${BOLD}=== {{DDEV_NAME}} dev environment setup ===${RESET}"; echo ""

# --- Prerequisites ---
info "Checking prerequisites..."
command -v ddev &>/dev/null || error "DDEV not found. Install from https://ddev.com then re-run."
command -v git  &>/dev/null || error "git not found."
success "DDEV: $(ddev version | head -1)"

# --- Agent resources (skills) ---
info "Installing Claude Code / Cursor skills via agr..."
if command -v agr &>/dev/null; then
  # Prefer the lockfile so every clone gets identical, pinned skills.
  if [ -f "agr.lock" ]; then
    agr sync
    success "Skills installed from agr.lock (agr sync)."
  else
    agr add madsnorgaard/drupal-agent-resources/drupal-expert --overwrite
    agr add madsnorgaard/drupal-agent-resources/ddev-expert --overwrite
    agr add "${SKILL_FORK}/drupal-agent-resources/drupal-localgov" --overwrite
    success "Skills installed and locked (drupal-expert, ddev-expert, drupal-localgov)."
  fi
else
  warn "agr not found, skipping skills. Install later: uv tool install agr && agr sync"
fi

# --- drupal-reviewer agent ---
# The tracked copy is canonical; only fetch when missing (or --force-reviewer).
info "Ensuring drupal-reviewer agent..."
mkdir -p .claude/agents
if [ -f ".claude/agents/drupal-reviewer.md" ] && [ "$FORCE_REVIEWER" -eq 0 ]; then
  success "drupal-reviewer already present (tracked copy kept). Use --force-reviewer to refresh."
elif command -v curl &>/dev/null; then
  curl -fsSL -o .claude/agents/drupal-reviewer.md "${REVIEWER_URL}" \
    && success "drupal-reviewer fetched (${REVIEWER_REF})." \
    || warn "Could not fetch drupal-reviewer. Save manually from ${REVIEWER_URL}"
else
  warn "curl not found, save drupal-reviewer manually from ${REVIEWER_URL}"
fi

# --- Claude settings.local.json ---
if [ ! -f ".claude/settings.local.json" ] && [ -f ".claude/settings.local.json.dist" ]; then
  info "Creating .claude/settings.local.json from dist..."
  sed "s|<absolute-path-to-repo>|$(pwd)|g" .claude/settings.local.json.dist > .claude/settings.local.json
  success ".claude/settings.local.json created."
else
  success ".claude/settings.local.json present or no dist, skipping."
fi

# --- Optional: clone the target module into place ---
if [ -n "${MODULE_REPO}" ] && [ ! -d "${MODULE_PATH}" ]; then
  info "Cloning module into ${MODULE_PATH}..."
  mkdir -p "$(dirname "${MODULE_PATH}")"
  git clone "${MODULE_REPO}" "${MODULE_PATH}" && success "Module cloned." || warn "Module clone failed; clone manually."
else
  success "Module clone skipped (no MODULE_REPO or path exists)."
fi

echo ""; success "Setup complete. Next: ddev start"
