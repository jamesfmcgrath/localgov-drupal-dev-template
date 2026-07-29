#!/usr/bin/env bash
# Regression suite for the bare template. Exercises scripts/init.sh across
# every supported flavour/version combo in a throwaway copy and asserts
# tokeniser + file invariants. No network, no composer, no DDEV: the live
# spin-up remains a manual verification step (see PROJECT.md).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BOLD="\033[1m"; GREEN="\033[32m"; RED="\033[31m"; RESET="\033[0m"

TOTAL_PASS=0
TOTAL_FAIL=0

pass() { TOTAL_PASS=$((TOTAL_PASS + 1)); echo -e "  ${GREEN}OK${RESET}   $*"; }
fail() { TOTAL_FAIL=$((TOTAL_FAIL + 1)); echo -e "  ${RED}FAIL${RESET} $*"; }

# One entry per supported flavour/version pair:
#   flavour|version|expected DRUPAL_TYPE|expected COMPOSER_PROJECT|expected INSTALL_PROFILE
# Add a line here when a new flavour lands (e.g. cms 11 for Stage 5); this is
# the only place a new combo needs to register its expected derived values.
COMBOS=(
  "localgov|11|drupal11|drupal/localgov_project|localgov"
  "localgov|10|drupal10|drupal/localgov_project:^3.0|localgov"
  "vanilla|11|drupal11|drupal/recommended-project:^11|standard"
  "vanilla|10|drupal10|drupal/recommended-project:^10|standard"
)

MODULE_NAME="regress_mod"

# Files that document the {{UPPER_SNAKE}} token convention as literal text
# (companion maintainer docs), not files init.sh substitutes into.
TOKEN_DOC_EXCEPTIONS=("PROJECT.md" "PROMPTS.md")

yaml_parse() {
  local f="$1"
  if command -v ruby >/dev/null 2>&1; then
    ruby -ryaml -e "YAML.load_file(ARGV[0])" "$f" >/dev/null 2>&1
  elif python3 -c "import yaml" >/dev/null 2>&1; then
    python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" >/dev/null 2>&1
  else
    echo "  no YAML parser (ruby or python3+PyYAML) available" >&2
    return 1
  fi
}

run_combo() {
  local flavour="$1" version="$2" drupal_type="$3" composer_project="$4" install_profile="$5"
  local label="$flavour $version"

  echo ""
  echo -e "${BOLD}== $label ==${RESET}"

  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/test-template.XXXXXX")"
  rsync -a --exclude='.git' --exclude='_to_delete' "$REPO_ROOT"/ "$tmp_dir"/ >/dev/null

  local ci_before ci_after
  ci_before="$(grep -oF '${{' "$tmp_dir/.github/workflows/ci.yml" | wc -l | tr -d ' ')"

  local init_log="$tmp_dir/.init-output.log"
  if (cd "$tmp_dir" && printf 'regress_mod\n\n\n\n\n\n\n\n%s\n%s\n' "$flavour" "$version" | ./scripts/init.sh) >"$init_log" 2>&1; then
    pass "$label: init.sh exits 0"
  else
    fail "$label: init.sh exited nonzero (see $init_log)"
  fi

  # a. init.sh, TEMPLATE.md, and test-template.sh removed themselves.
  if [ ! -e "$tmp_dir/scripts/init.sh" ]; then pass "$label: scripts/init.sh removed itself"; else fail "$label: scripts/init.sh still present"; fi
  if [ ! -e "$tmp_dir/TEMPLATE.md" ]; then pass "$label: TEMPLATE.md removed"; else fail "$label: TEMPLATE.md still present"; fi
  if [ ! -e "$tmp_dir/scripts/test-template.sh" ]; then pass "$label: scripts/test-template.sh removed"; else fail "$label: scripts/test-template.sh still present"; fi

  # b. no {{UPPER_SNAKE}} tokens remain, except in the documented exceptions.
  local exclude_args=()
  for ex in "${TOKEN_DOC_EXCEPTIONS[@]}"; do exclude_args+=(--exclude="$ex"); done
  local leftover
  leftover="$(grep -rlE '\{\{[A-Z_]+\}\}' "$tmp_dir" --exclude-dir=.git "${exclude_args[@]}" 2>/dev/null || true)"
  if [ -z "$leftover" ]; then
    pass "$label: no {{UPPER_SNAKE}} tokens remain outside ${TOKEN_DOC_EXCEPTIONS[*]}"
  else
    fail "$label: leftover tokens in: $(echo "$leftover" | tr '\n' ' ')"
  fi

  # c. ${{ count in ci.yml unchanged (GitHub Actions expressions untouched).
  ci_after="$(grep -oF '${{' "$tmp_dir/.github/workflows/ci.yml" | wc -l | tr -d ' ')"
  if [ "$ci_before" = "$ci_after" ]; then
    pass "$label: \${{ count in ci.yml unchanged ($ci_before)"
  else
    fail "$label: \${{ count in ci.yml changed ($ci_before -> $ci_after)"
  fi

  # d. substituted values present where each applies.
  for f in AGENTS.md Makefile .claude/settings.local.json.dist .claude/commands/a11y-check.md; do
    if grep -q "$MODULE_NAME" "$tmp_dir/$f" 2>/dev/null; then
      pass "$label: $f contains $MODULE_NAME"
    else
      fail "$label: $f missing $MODULE_NAME"
    fi
  done
  if grep -qF "$drupal_type" "$tmp_dir/.ddev/config.yaml" 2>/dev/null; then
    pass "$label: .ddev/config.yaml contains $drupal_type"
  else
    fail "$label: .ddev/config.yaml missing $drupal_type"
  fi
  if grep -qF "$composer_project" "$tmp_dir/scripts/setup.sh" 2>/dev/null; then
    pass "$label: scripts/setup.sh contains $composer_project"
  else
    fail "$label: scripts/setup.sh missing $composer_project"
  fi
  if grep -qF "$install_profile" "$tmp_dir/scripts/setup.sh" 2>/dev/null; then
    pass "$label: scripts/setup.sh contains $install_profile"
  else
    fail "$label: scripts/setup.sh missing $install_profile"
  fi
  if grep -qF "$install_profile" "$tmp_dir/.github/workflows/ci.yml" 2>/dev/null; then
    pass "$label: ci.yml contains $install_profile"
  else
    fail "$label: ci.yml missing $install_profile"
  fi

  # e. bash -n on portable scripts; executable bits preserved.
  if bash -n "$tmp_dir/scripts/setup.sh" 2>/dev/null; then pass "$label: scripts/setup.sh bash -n"; else fail "$label: scripts/setup.sh bash -n failed"; fi
  if bash -n "$tmp_dir/scripts/install-drupal" 2>/dev/null; then pass "$label: scripts/install-drupal bash -n"; else fail "$label: scripts/install-drupal bash -n failed"; fi
  if [ -x "$tmp_dir/scripts/setup.sh" ]; then pass "$label: scripts/setup.sh executable"; else fail "$label: scripts/setup.sh not executable"; fi
  if [ -x "$tmp_dir/scripts/install-drupal" ]; then pass "$label: scripts/install-drupal executable"; else fail "$label: scripts/install-drupal not executable"; fi

  # f. make/JSON/YAML parse.
  if (cd "$tmp_dir" && make -n help) >/dev/null 2>&1; then pass "$label: make -n help parses"; else fail "$label: make -n help failed"; fi
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$tmp_dir/.claude/settings.local.json.dist" 2>/dev/null; then
    pass "$label: settings.local.json.dist is valid JSON"
  else
    fail "$label: settings.local.json.dist is not valid JSON"
  fi
  if yaml_parse "$tmp_dir/.github/workflows/ci.yml"; then pass "$label: ci.yml is valid YAML"; else fail "$label: ci.yml is not valid YAML"; fi
  if yaml_parse "$tmp_dir/.ddev/config.yaml"; then pass "$label: .ddev/config.yaml is valid YAML"; else fail "$label: .ddev/config.yaml is not valid YAML"; fi

  rm -rf "$tmp_dir"
}

for combo in "${COMBOS[@]}"; do
  IFS='|' read -r flavour version drupal_type composer_project install_profile <<< "$combo"
  run_combo "$flavour" "$version" "$drupal_type" "$composer_project" "$install_profile"
done

echo ""
echo -e "${BOLD}== Summary ==${RESET}"
if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo -e "  ${GREEN}$TOTAL_PASS passed${RESET}, ${RED}$TOTAL_FAIL failed${RESET}"
  exit 1
fi
echo -e "  ${GREEN}$TOTAL_PASS passed${RESET}, 0 failed"
exit 0
