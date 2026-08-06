#!/usr/bin/env bash
# Regression suite for the bare template. Exercises scripts/init.sh across
# every supported flavour/version combo, and across all four module/theme
# combinations, in a throwaway copy, then asserts tokeniser + file invariants.
# No network, no composer, no DDEV: the live spin-up remains a manual
# verification step (see PROJECT.md).
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
# Add a line here when a new flavour lands; this is the only place a new combo
# needs to register its expected derived values. cms is Drupal 11 only, and its
# INSTALL_PROFILE is a recipe path rather than a profile machine name.
COMBOS=(
  "localgov|11|drupal11|drupal/localgov_project|localgov"
  "localgov|10|drupal10|drupal/localgov_project:^3.0|localgov"
  "vanilla|11|drupal11|drupal/recommended-project:^11|standard"
  "vanilla|10|drupal10|drupal/recommended-project:^10|standard"
  "cms|11|drupal11|drupal/cms|recipes/drupal_cms_starter"
)

MODULE_NAME="regress_mod"
THEME_NAME="regress_theme"
THEME_LABEL="Regress Theme"

# Files that document the {{UPPER_SNAKE}} token convention as literal text
# (companion maintainer docs), not files init.sh substitutes into.
TOKEN_DOC_EXCEPTIONS=("PROJECT.md" "PROMPTS.md" "memory.md")

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

# Feed init.sh's prompts in order. A blank line accepts the offered default.
# Prompt order: module name, [module label, module path, module git URL],
# theme name, [theme label], DDEV name, DDEV URL, client, skill fork,
# flavour, version.
init_input() { # init_input <module_name> <theme_name> <flavour> <version>
  local module="$1" theme="$2" flavour="$3" version="$4"
  printf '%s\n' "$module"
  [ -n "$module" ] && printf '\n\n\n'
  printf '%s\n' "$theme"
  [ -n "$theme" ] && printf '\n'
  printf '\n\n\n\n'
  printf '%s\n%s\n' "$flavour" "$version"
}

stage_copy() { # stage_copy <dest>
  rsync -a --exclude='.git' --exclude='_to_delete' --exclude='.superpowers' \
    --exclude='docs' --exclude='.claude/settings.local.json' \
    --exclude='node_modules' --exclude='package-lock.json' \
    "$REPO_ROOT"/ "$1"/ >/dev/null
}

assert_no_leftover_tokens() { # assert_no_leftover_tokens <dir> <label>
  local dir="$1" label="$2" ex leftover
  local exclude_args=()
  for ex in "${TOKEN_DOC_EXCEPTIONS[@]}"; do exclude_args+=(--exclude="$ex"); done
  leftover="$(grep -rlE '\{\{[A-Z_]+\}\}' "$dir" --exclude-dir=.git "${exclude_args[@]}" 2>/dev/null || true)"
  if [ -z "$leftover" ]; then
    pass "$label: no {{UPPER_SNAKE}} tokens remain outside ${TOKEN_DOC_EXCEPTIONS[*]}"
  else
    fail "$label: leftover tokens in: $(echo "$leftover" | tr '\n' ' ')"
  fi
}

# Theme-mode assertions. Run for every combo: with a theme name the THEME_*
# tokens must carry the answers through; without one they must still resolve
# to something sane and the Makefile must still parse.
assert_theme() { # assert_theme <dir> <label> <theme_name>
  local dir="$1" label="$2" theme="$3"

  if [ -n "$theme" ]; then
    if grep -q "^THEME_NAME = $theme$" "$dir/Makefile" 2>/dev/null; then
      pass "$label: Makefile THEME_NAME is $theme"
    else
      fail "$label: Makefile THEME_NAME is not $theme"
    fi
    if grep -q "^THEME_PATH = web/themes/custom/$theme$" "$dir/Makefile" 2>/dev/null; then
      pass "$label: Makefile THEME_PATH is web/themes/custom/$theme"
    else
      fail "$label: Makefile THEME_PATH is not web/themes/custom/$theme"
    fi
    if grep -q "^THEME_LABEL = $THEME_LABEL$" "$dir/Makefile" 2>/dev/null; then
      pass "$label: Makefile THEME_LABEL is $THEME_LABEL"
    else
      fail "$label: Makefile THEME_LABEL is not $THEME_LABEL"
    fi
    for f in AGENTS.md .claude/commands/a11y-check.md; do
      if grep -q "$theme" "$dir/$f" 2>/dev/null; then
        pass "$label: $f contains $theme"
      else
        fail "$label: $f missing $theme"
      fi
    done
  else
    if grep -q "^THEME_NAME = $" "$dir/Makefile" 2>/dev/null; then
      pass "$label: Makefile THEME_NAME is empty (no custom theme)"
    else
      fail "$label: Makefile THEME_NAME is not empty"
    fi
    if grep -q "no custom theme" "$dir/AGENTS.md" 2>/dev/null; then
      pass "$label: AGENTS.md records that there is no custom theme"
    else
      fail "$label: AGENTS.md does not record the no-theme state"
    fi
  fi

  if (cd "$dir" && make -n subtheme) >/dev/null 2>&1; then
    pass "$label: make -n subtheme parses"
  else
    fail "$label: make -n subtheme failed"
  fi
  if (cd "$dir" && make -n component NAME=demo_card) >/dev/null 2>&1; then
    pass "$label: make -n component parses"
  else
    fail "$label: make -n component failed"
  fi
}

# Shared per-run assertions: the invariants that must hold after init.sh no
# matter which module/theme/flavour combination was answered.
assert_common() { # assert_common <dir> <label>
  local dir="$1" label="$2"

  if [ ! -e "$dir/scripts/init.sh" ]; then pass "$label: scripts/init.sh removed itself"; else fail "$label: scripts/init.sh still present"; fi
  if [ ! -e "$dir/TEMPLATE.md" ]; then pass "$label: TEMPLATE.md removed"; else fail "$label: TEMPLATE.md still present"; fi
  if [ ! -e "$dir/scripts/test-template.sh" ]; then pass "$label: scripts/test-template.sh removed"; else fail "$label: scripts/test-template.sh still present"; fi

  assert_no_leftover_tokens "$dir" "$label"

  if bash -n "$dir/scripts/setup.sh" 2>/dev/null; then pass "$label: scripts/setup.sh bash -n"; else fail "$label: scripts/setup.sh bash -n failed"; fi
  if bash -n "$dir/scripts/install-drupal" 2>/dev/null; then pass "$label: scripts/install-drupal bash -n"; else fail "$label: scripts/install-drupal bash -n failed"; fi
  if [ -x "$dir/scripts/setup.sh" ]; then pass "$label: scripts/setup.sh executable"; else fail "$label: scripts/setup.sh not executable"; fi
  if [ -x "$dir/scripts/install-drupal" ]; then pass "$label: scripts/install-drupal executable"; else fail "$label: scripts/install-drupal not executable"; fi

  if (cd "$dir" && make -n help) >/dev/null 2>&1; then pass "$label: make -n help parses"; else fail "$label: make -n help failed"; fi
  if (cd "$dir" && make -n module-ci) >/dev/null 2>&1; then pass "$label: make -n module-ci parses"; else fail "$label: make -n module-ci failed"; fi

  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$dir/.claude/settings.local.json.dist" 2>/dev/null; then
    pass "$label: settings.local.json.dist is valid JSON"
  else
    fail "$label: settings.local.json.dist is not valid JSON"
  fi
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$dir/package.json" 2>/dev/null; then
    pass "$label: package.json is valid JSON"
  else
    fail "$label: package.json is not valid JSON"
  fi
  if yaml_parse "$dir/.github/workflows/ci.yml"; then pass "$label: ci.yml is valid YAML"; else fail "$label: ci.yml is not valid YAML"; fi
  if yaml_parse "$dir/.ddev/config.yaml"; then pass "$label: .ddev/config.yaml is valid YAML"; else fail "$label: .ddev/config.yaml is not valid YAML"; fi
  if python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse(sys.argv[1])" "$dir/phpcs.xml.dist" 2>/dev/null; then
    pass "$label: phpcs.xml.dist is valid XML"
  else
    fail "$label: phpcs.xml.dist is not valid XML"
  fi

  # assets/module.gitlab-ci.yml holds no {{TOKENS}}, so it must survive verbatim.
  if diff -q "$REPO_ROOT/assets/module.gitlab-ci.yml" "$dir/assets/module.gitlab-ci.yml" >/dev/null 2>&1; then
    pass "$label: assets/module.gitlab-ci.yml survives init.sh verbatim"
  else
    fail "$label: assets/module.gitlab-ci.yml changed or missing after init.sh"
  fi

  # The custom code workspace is the scoping unit for the quality tooling.
  for f in phpcs.xml.dist phpstan.neon package.json .github/workflows/ci.yml; do
    if grep -q 'web/modules/custom' "$dir/$f" 2>/dev/null && grep -q 'web/themes/custom' "$dir/$f" 2>/dev/null; then
      pass "$label: $f covers both custom code paths"
    else
      fail "$label: $f does not cover both custom code paths"
    fi
  done
  if grep -q '^LINT_PATHS = web/modules/custom web/themes/custom$' "$dir/Makefile" 2>/dev/null; then
    pass "$label: Makefile LINT_PATHS covers both custom code paths"
  else
    fail "$label: Makefile LINT_PATHS does not cover both custom code paths"
  fi
}

run_combo() { # run_combo <flavour> <version> <drupal_type> <composer_project> <install_profile> <module_name> <theme_name> <label_suffix>
  local flavour="$1" version="$2" drupal_type="$3" composer_project="$4" install_profile="$5"
  local module="$6" theme="$7" suffix="${8:-}"
  local label="$flavour $version${suffix:+ ($suffix)}"

  echo ""
  echo -e "${BOLD}== $label ==${RESET}"

  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/test-template.XXXXXX")"
  stage_copy "$tmp_dir"

  local ci_before ci_after
  ci_before="$(grep -oF '${{' "$tmp_dir/.github/workflows/ci.yml" | wc -l | tr -d ' ')"

  local init_log="$tmp_dir/.init-output.log"
  if (cd "$tmp_dir" && init_input "$module" "$theme" "$flavour" "$version" | ./scripts/init.sh) >"$init_log" 2>&1; then
    pass "$label: init.sh exits 0"
  else
    fail "$label: init.sh exited nonzero (see $init_log)"
  fi

  assert_common "$tmp_dir" "$label"

  # GitHub Actions ${{ ... }} expressions must survive untouched.
  ci_after="$(grep -oF '${{' "$tmp_dir/.github/workflows/ci.yml" | wc -l | tr -d ' ')"
  if [ "$ci_before" = "$ci_after" ]; then
    pass "$label: \${{ count in ci.yml unchanged ($ci_before)"
  else
    fail "$label: \${{ count in ci.yml changed ($ci_before -> $ci_after)"
  fi

  # Module answers land where they apply.
  if [ -n "$module" ]; then
    for f in AGENTS.md Makefile .claude/settings.local.json.dist .claude/commands/a11y-check.md; do
      if grep -q "$module" "$tmp_dir/$f" 2>/dev/null; then
        pass "$label: $f contains $module"
      else
        fail "$label: $f missing $module"
      fi
    done
  else
    if grep -q '^MODULE_NAME = $' "$tmp_dir/Makefile" 2>/dev/null; then
      pass "$label: Makefile MODULE_NAME is empty (no module)"
    else
      fail "$label: Makefile MODULE_NAME is not empty"
    fi
  fi

  assert_theme "$tmp_dir" "$label" "$theme"

  # Flavour/version answers land in the derived values.
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

  rm -rf "$tmp_dir"
}

for combo in "${COMBOS[@]}"; do
  IFS='|' read -r flavour version drupal_type composer_project install_profile <<< "$combo"
  run_combo "$flavour" "$version" "$drupal_type" "$composer_project" "$install_profile" "$MODULE_NAME" ""
done

# All four module/theme combinations. Module only is covered above; these add
# module plus theme, theme only, and neither.
run_combo "localgov" "11" "drupal11" "drupal/localgov_project" "localgov" "$MODULE_NAME" "$THEME_NAME" "module + theme"
run_combo "localgov" "11" "drupal11" "drupal/localgov_project" "localgov" "" "$THEME_NAME" "theme only"
run_combo "vanilla"  "11" "drupal11" "drupal/recommended-project:^11" "standard" "" "$THEME_NAME" "theme only"
run_combo "cms"      "11" "drupal11" "drupal/cms" "recipes/drupal_cms_starter" "$MODULE_NAME" "$THEME_NAME" "module + theme"
run_combo "localgov" "11" "drupal11" "drupal/localgov_project" "localgov" "" "" "site-only"
run_combo "cms"      "11" "drupal11" "drupal/cms" "recipes/drupal_cms_starter" "" "" "site-only"

echo ""
echo -e "${BOLD}== Summary ==${RESET}"
if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo -e "  ${GREEN}$TOTAL_PASS passed${RESET}, ${RED}$TOTAL_FAIL failed${RESET}"
  exit 1
fi
echo -e "  ${GREEN}$TOTAL_PASS passed${RESET}, 0 failed"
exit 0
