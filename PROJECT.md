# Maintaining this template

This file holds the Claude Project setup for keeping
`localgov-drupal-dev-template` up to date and improving it. Copy the blocks
below into a Claude Project (instructions box and first message).

The repo is a GitHub template: people create a project from it, run
`./scripts/init.sh`, then `./scripts/setup.sh`, and get a running Drupal or
LocalGov Drupal site ready to code in.

## Project instructions

You help maintain and improve the localgov-drupal-dev-template repo
(github.com/jamesfmcgrath/localgov-drupal-dev-template). It is a GitHub
"template repository": people create a project from it, run ./scripts/init.sh,
then ./scripts/setup.sh, and get a running Drupal site ready to code in.

Staged improvement prompts and their current status live in PROMPTS.md; read
it alongside this file when planning work.

### What the template contains

- scripts/init.sh: one-time tokeniser. Prompts for module name/path, theme
  name/label, DDEV site, client, skill fork, and Drupal flavour
  (localgov|vanilla|cms) + version (11|10; the cms flavour forces Drupal 11).
  Every prompt has a matching flag (--module, --module-label, --module-path,
  --module-repo, --theme, --theme-label, --ddev-name, --ddev-url, --client,
  --skill-fork, --flavour, --version), plus --defaults (take every default,
  blank module and theme) and --help. Anything not given as a flag is still
  prompted, so flags and prompts mix; with --defaults or a full flag set the
  run needs no tty. --flag=value is the explicit-empty form, so --module=""
  selects site-only mode rather than falling back to the prompt. Flag values
  are validated before the first prompt (machine names, non-empty values,
  flavour, version); the prompts keep their historic permissive fallback.
  Module and theme are independent optional answers, so all four combinations
  are supported: module only, theme only, both, neither. A blank module name
  skips the module label/path/repo prompts and makes MODULE_PATH
  web/modules/custom; a blank theme name skips the theme label prompt and makes
  THEME_PATH web/themes/custom. Eight composed tokens (MODULE_INTRO,
  MODULE_LINE, MODULE_AFFECTS, THEME_INTRO, THEME_LINE, THEME_LAYER,
  PACKAGE_NAME, PACKAGE_DESCRIPTION) keep AGENTS.md, a11y-check.md, and
  package.json reading naturally in every combination. Writes the resolved
  answers to template.answers (KEY=value lines, keys matching the flag names,
  plus the four derived values) before substituting, and leaves that file in
  place to be committed, so a run is auditable and reproducible. Substitutes
  {{TOKENS}} across files, then removes itself, TEMPLATE.md, and
  scripts/test-template.sh. Must preserve file executable bits (it writes back
  into files rather than mv-ing a temp over them, and re-chmods the scripts).
  The substitution file list is discovered per run with
  grep -rlE for {{UPPER_SNAKE}}, not hand-maintained, so a new template file is
  picked up automatically; excluded are .git, node_modules, vendor, web, docs,
  template-docs, the token-convention docs (PROJECT.md, PROMPTS.md, memory.md),
  template.answers, and the two self-deleting scripts (rewriting init.sh while
  bash is still reading it would corrupt the run). Values are sed-escaped, so a
  client name containing & survives.
- scripts/test-template.sh: regression suite for the bare template. Copies the
  repo to a throwaway dir per supported flavour/version combo and per
  module/theme combination, runs init.sh with flags and stdin closed (so a run
  that still reaches a prompt fails), and asserts the tokeniser and file
  invariants (no leftover {{TOKENS}}, GitHub Actions ${{ }} expressions
  untouched, substituted values present, each flag's value landing in the file
  that carries it, template.answers written with the prompted and derived
  values, THEME_* values landing in the Makefile/AGENTS.md/a11y-check.md,
  LINT_PATHS covering both custom code paths in all five places, scripts still
  parse and stay executable, JSON/YAML/XML still parse, make -n help/module-ci/
  subtheme/component all parse). Exactly one combo (localgov 11, module +
  theme) drives the interactive path instead, through the init_input helper
  that emits the prompt sequence. One combo injects a scratch file containing a
  {{CLIENT}} token into the copy before running init.sh and asserts it was
  substituted, which is what keeps the file list honest now that it is
  discovered rather than listed. The test client name contains an ampersand on
  purpose, to hold the sed escaping in place. No network, composer, or DDEV;
  the live spin-up still needs manual verification. Removes itself on init,
  same as TEMPLATE.md.
- scripts/setup.sh: one-command spin-up. Installs agr skills + drupal-reviewer,
  starts DDEV, scaffolds the Drupal project (composer create into a container
  temp dir then cp -n so template files are not clobbered), composer install,
  adds dev tooling (composer require -W, needed since drupal/core-dev does not
  always resolve cleanly against the vanilla flavour's current lock without
  it; includes drush/drush since only the LocalGov distribution bundles drush
  by default), clones the module if a repo URL was given, runs install-drupal,
  enables the module. Flags: --skip-install, --force-reviewer.
- scripts/install-drupal: profile picker (Standard/Umami/LocalGov/+Demo/
  Microsites/+Elections/Drupal CMS starter); accepts a profile arg
  (case-insensitive for "standard", matching init.sh's lowercase
  INSTALL_PROFILE) or runs interactively. For the cms flavour the arg is a
  recipe path (recipes/drupal_cms_starter), which maps to
  drush si recipes/drupal_cms_starter.
- Tooling: .ddev/config.yaml (with test env), phpcs.xml.dist (Drupal +
  DrupalPractice), phpstan.neon (phpstan-drupal), PHPUnit via `-c web/core` plus
  DDEV web_environment, vincentlanglet/twig-cs-fixer for Twig linting (Prettier
  does not cover Twig), Prettier (package.json + .prettierrc.json), a tokenised
  Makefile, .editorconfig.
- Custom code workspace: the quality tooling scopes to a list of paths, not to
  one module. LINT_PATHS in the Makefile defaults to
  "web/modules/custom web/themes/custom" and the Makefile quality targets
  (lint, lint-fix, stan, test, twig-lint, twig-fix, spell, lint-js, lint-css,
  format, format-check) iterate over it, keeping the per-target
  "no files, skipping" guards. The same list is mirrored as <file> entries in
  phpcs.xml.dist, paths in phpstan.neon, globs in package.json, and a job-level
  LINT_PATHS env var in .github/workflows/ci.yml: five places to keep in step.
  setup.sh and CI mkdir -p both paths so a bare phpcs/phpstan run works on a
  project that has only modules or only a theme. $(MODULE) and $(MODULE_NAME)
  remain for enable, module-ci, and the mod-* git targets.
- Theme targets: make subtheme scaffolds the configured theme at $(THEME_PATH),
  guarded by guard-theme-name and by an already-exists check. On the localgov
  flavour it feeds the theme label and machine name into
  web/themes/contrib/localgov_base/scripts/create_subtheme.sh (the generator
  LocalGov Base ships; verified against localgov_base 2.x, the current branch
  since 1.x bug fixes ended December 2025); on vanilla and cms it runs
  php web/core/scripts/drupal generate-theme <name> --name "<label>"
  --path themes/custom. make component NAME=x wraps
  drush generate single-directory-component, pre-filling its first three
  answers (theme machine name, component name, component machine name) via
  --answer and leaving the component shape questions interactive.
- Local dev recipes: assets/settings.local.php and assets/development.services.yml
  (Twig debug on, Twig cache off, render/page/dynamic_page_cache bins
  null-backed) are copied by setup.sh into web/sites/default/ and web/sites/
  only when absent, and setup.sh activates the include in
  web/sites/default/settings.php (uncomments Drupal's own commented block if
  present, appends the standard guarded include if not; never touches DDEV's
  own settings.ddev.php include). recipes/dev_tools (devel,
  environment_indicator, environment_indicator_toolbar) and recipes/site_tools
  (admin_toolbar, admin_toolbar_tools, twig_tweak, eca, eca_ui, bpmn_io) apply
  via ddev drush recipe after the site install, site_tools then dev_tools,
  followed by one more drush cex; config_exclude_modules in
  settings.local.php keeps devel and environment_indicator_toolbar out of
  that export (environment_indicator itself is not excluded, so it flows to
  every environment through normal config sync). ECA and bpmn_io are
  version-paired with Drupal core in setup.sh's composer require: ^3.1/^3.0
  on Drupal 11 (ECA 3.x needs core 11.3+), ^2.1/^2.0 on Drupal 10.
  drupal/core-recipe-unpack is required and pre-authorised
  (allow-plugins.drupal/core-recipe-unpack) alongside them. make recipe
  R=path applies any recipe; --no-site-tools and --no-dev-tools skip either
  recipe independently in setup.sh.
- CI: .github/workflows/ci.yml runs phpcs, phpstan, twig-cs-fixer (guarded to
  skip cleanly when the module has no .twig files), phpunit (unit+kernel,
  sqlite), a prettier check, and a "browser checks" job. That job installs the
  site with drush si and sqlite, serves it with drush rs (falling back to php
  -S if that misbehaves), creates a node via drush, then runs two Playwright
  passes against the served site: scripts/a11y-scan.mjs (axe-core, WCAG 2.2
  AA), then tests/vrt/vrt.spec.mjs (visual regression, see below). Both read
  the same shared URL list, scan-urls.json, which the job rebuilds at runtime
  to match the installed site: always the front page, the node it just
  created addressed by its real id, and /search only when the site actually
  serves it. This caters to each flavour and recipe instead of assuming
  /search and /node/1 exist, without suppressing any real violation or visual
  diff on the pages that do load. The file shipped at the template root
  (scan-urls.json) ships with just `["/"]`, the only path guaranteed to
  resolve on every flavour (localgov, vanilla standard, and cms) straight
  after install with no content or extra module; add real paths (a node once
  one exists, a search route once one is enabled, your own listing/detail
  pages) as a project grows. A guard job checks whether composer.json is
  present: created projects skip straight to the jobs above; the bare
  template runs a "template" job instead (scripts/test-template.sh), so the
  template repo gets a real, green CI run instead of one that skips
  everything.
- Visual regression testing (VRT): tests/vrt/vrt.spec.mjs reuses the
  @playwright/test stack the accessibility job already installs rather than
  adding a second browser-automation dependency (BackstopJS). It reads
  scan-urls.json and asserts `expect(page).toHaveScreenshot()` per path
  (fullPage, animations disabled, maxDiffPixelRatio 0.01), scoped by its own
  playwright.config.mjs (testDir: tests/vrt) so a bare `npx playwright test`
  does not pick up anything else. Baselines are OS-suffixed by Playwright's
  own snapshot naming (tests/vrt/__screenshots__/<platform>/...); only the
  linux/ ones are authoritative and committed, since font rendering differs
  enough between macOS and Linux to make cross-OS baselines flaky by
  construction. The darwin/ (macOS) directory is gitignored, so a local run
  on a Mac is advisory only, not something to commit; generate and compare
  authoritative baselines inside CI or a Linux container. `make vrt` runs the
  comparison, `make vrt-update` regenerates baselines (both carry the same
  Linux-only-authoritative note). In CI, the browser checks job treats a
  missing linux/ baseline as "generate it and upload as a build artifact",
  not a failure, so a brand-new project's first run does not fail on the
  absence of history; once that artifact's contents are committed, later
  diffs fail the job and the HTML diff report uploads as an artifact.
  BackstopJS (including the official ddev/ddev-backstopjs add-on) remains a
  documented, supported alternative for teams that specifically want its
  standalone HTML report UI; this template does not run two browser-test
  stacks side by side, since @playwright/test already covers the same ground
  with the install already in place for accessibility testing.
- drupal.org pipeline parity: assets/module.gitlab-ci.yml ships the canonical
  gitlab_templates include block (three files: main, variables, workflows)
  plus a documented variables block. `make module-ci` copies it to
  $(MODULE)/.gitlab-ci.yml, refusing if one exists. Twig CS Fixer defaults to
  SKIPPED upstream (SKIP_TWIG_CS_FIXER: '1'); the shipped file overrides it
  to '0' since this template already lints Twig locally and in GitHub
  Actions. Local parity: cspell.json + .cspell-project-words.txt at the
  template root wired to `make spell`; `make lint-js` and `make lint-css`
  reuse Drupal core's own installed ESLint/Stylelint config and binaries
  from web/core/node_modules, the same approach the drupalcode CI jobs use,
  guarded to skip with a message when the module has no .js/.css files.
  Prettier's CSS output does not shorten hex colors, which core's Stylelint
  config requires (color-hex-length: short); this is a known, verified gap
  with no config fix, write short hex or run stylelint --fix. GitHub
  Actions ci.yml mirrors the same three checks (CSpell in the prettier job,
  ESLint/Stylelint in the php job after composer install). Nightwatch and
  Composer Lint have no local or GitHub Actions equivalent and stay
  CI-only, same category as the a11y job. cspell.json and
  .cspell-project-words.txt live at this template's root; `make module-ci`
  does not copy them, so a module split into its own drupalcode repo needs
  its own copies for full parity on that job.
- Agent resources: agr.toml installs drupal-expert, ddev-expert, and
  drupal-localgov (from jamesfmcgrath/drupal-agent-resources). Standards live in
  AGENTS.md, the single source of truth; CLAUDE.md is only the @AGENTS.md import
  stub (Cursor reads AGENTS.md natively, .cursorrules is retired). The
  accessibility audit workflow lives in .claude/commands/a11y-check.md; the
  target is WCAG 2.2 AA, legal floor WCAG 2.1 AA / EN 301 549.

### Tokens (substituted by init.sh)

Prompted: MODULE_NAME, MODULE_LABEL, MODULE_PATH, MODULE_REPO, THEME_NAME,
THEME_LABEL, DDEV_NAME, DDEV_URL, CLIENT, SKILL_FORK. Derived: THEME_PATH (from
THEME_NAME), and from flavour/version DRUPAL_TYPE, DRUPAL_FLAVOUR,
COMPOSER_PROJECT, INSTALL_PROFILE. Composed prose tokens: MODULE_INTRO,
MODULE_LINE, MODULE_AFFECTS, THEME_INTRO, THEME_LINE, THEME_LAYER,
PACKAGE_NAME, PACKAGE_DESCRIPTION. Only {{UPPER_SNAKE}} names are tokens; GitHub
Actions ${{ ... }} expressions must be left untouched. Every prompted token has
a flag of the same name (MODULE_NAME is --module, THEME_NAME is --theme, the
rest match directly), and the resolved set, prompted and derived, is recorded in
template.answers.

### Conventions

- No em dashes anywhere (use commas, colons, or restructure).
- Agent resource dirs (.claude/skills/, .cursor/skills/) are gitignored and
  reproduced by agr; do not vendor copies. Tracked: AGENTS.md, CLAUDE.md (import
  stub), agr.toml, agr.lock, .claude/agents/, .claude/commands/,
  .claude/settings.local.json.dist.
- Scripts must stay executable and be committed as 100755.
- Keep all three flavour branches (localgov, vanilla, cms) working, and both
  versions (10, 11) for localgov and vanilla; cms is Drupal 11 only.
- Keep all four module/theme combinations working: module only, theme only,
  both, and neither. Module mode's behaviour must never change as a side
  effect of theme or site-only work, or vice versa.
- LINT_PATHS is mirrored in five places (Makefile, phpcs.xml.dist,
  phpstan.neon, package.json, .github/workflows/ci.yml). Change it in all five
  or in none.

### Working rules for any change

- Run scripts/test-template.sh before calling a template change done.
- Smoke tests on a throwaway copy can drive init.sh with flags rather than
  piped answers, for example
  ./scripts/init.sh --defaults --module my_mod --flavour cms --version 11,
  which also proves the run needs no tty. Keep at least one check on the
  interactive prompt path.
- The DDEV/composer/npm spin-up cannot be fully proven without Docker; if you
  cannot run it, say so and mark it "needs live verification" rather than
  claiming success.
- State assumptions and proceed; ask only when the answer changes what you do.

### Status (2026-08-05)

Verified end to end on clean pulls for LocalGov + Drupal 11 and LocalGov +
Drupal 10. Vanilla + Drupal 11 also verified end to end (2026-07-28), which
surfaced and fixed three bugs: scripts/install-drupal only matched the
capitalised "Standard" option while init.sh passes lowercase "standard";
setup.sh's dev-tooling composer require failed to resolve against current
drupal/recommended-project without -W; and drush/drush was never installed
for the vanilla flavour (LocalGov bundles it, vanilla does not), so
setup.sh's dev-tooling require now includes drush/drush and passes -W. CI
added. Twig linting added via twig-cs-fixer (make twig-lint / twig-fix, wired
into CI); functional/browser tests not in CI. The a11y (pa11y-ci) CI job
needs live verification: it has only been checked for YAML syntax, not run
against GitHub Actions infrastructure. Vanilla + Drupal 10 verified end to
end (first run 2026-07-29, re-run 2026-08-05 with no issues): both vanilla
setup bugs above hold fixed on Drupal 10, the site installs and boots (Drupal
10.6.14, front page 200), and make check passes (phpcs, phpunit,
twig-cs-fixer clean; empty module test suite skips as expected). Known
caveat: `make stan` (ddev exec vendor/bin/phpstan analyse ...) can report a
spurious exit 1 with zero real errors, a ddev-exec/PHPStan process-exit
interaction, not a Drupal 10 or vanilla-flavour defect; running the identical
command through a shell (ddev exec bash -c "...") returns the correct exit 0.
Needs a proper fix or workaround in the Makefile if it recurs.

Stage 6, template regression suite: DONE. scripts/test-template.sh runs
init.sh against every supported flavour/version combo in throwaway copies and
asserts the tokeniser and file invariants; wired into CI as the "template"
job (runs when the guard job's composer.json check is false, the inverse of
the jobs above), so the bare template repo now gets a real, green CI run
instead of one that skips everything. The manual smoke-test convention in
Working Rules has been replaced by this suite; the DDEV/composer spin-up
still needs live verification, as before.

Stage 7, optional module (site-only mode): DONE. Tokeniser and file-invariant
work covered by scripts/test-template.sh's site-only regression check; the
full site-only DDEV/composer spin-up still needs a live run, same caveat as
the rest of setup.sh.

Stage 8, drupal.org (GitLab CI) pipeline parity: DONE. assets/module.gitlab-ci.yml
ships the canonical include block plus a variables block that turns Twig CS
Fixer back on (it defaults to skipped upstream, a fact confirmed directly
against the live gitlab_templates source, not assumed from the Stage 8
prompt text). make module-ci copies it into the module. Local parity added:
make spell (cspell.json + .cspell-project-words.txt), make lint-js and make
lint-css (Drupal core's own ESLint/Stylelint config and binaries from
web/core/node_modules), all wired into make check. GitHub Actions ci.yml
mirrors the same three checks. Actually running make lint-js/lint-css, and
the GitHub Actions eslint/stylelint steps end to end, needs a live DDEV
project with web/core's own frontend dependencies installed (`cd web/core &&
corepack enable && yarn install`, or the DDEV equivalent), which is outside
this stage's scope and still needs live verification, same caveat as the rest
of this template's DDEV-dependent tooling. Nightwatch (browser JS tests) has
no local equivalent and stays CI-only.

Stage 5, Drupal CMS ("cms") flavour: DONE at the tokeniser level (2026-08-05).
init.sh gained a cms branch (COMPOSER_PROJECT drupal/cms, INSTALL_PROFILE
recipes/drupal_cms_starter, Drupal 11 forced); install-drupal gained a
"Drupal CMS starter (recipe)" case running drush si recipes/drupal_cms_starter;
scripts/test-template.sh covers cms 11 and cms site-only, and now excludes the
gitignored node_modules and package-lock.json from its throwaway copy. The
regression suite passes 134/134. Verified against Drupal CMS 2.1.3, which
requires Drupal core 11 and PHP 8.3 (the DDEV config already pins php 8.3).
Live run in progress (2026-08-05): composer create-project and the recipe
install (drush si recipes/drupal_cms_starter) both succeed on Drupal CMS 2.1.x.
One bug found and fixed: Drupal CMS ships a stricter Composer allow-plugins
allowlist than the localgov and vanilla templates, so setup.sh's dev-tooling
require aborted on phpstan/extension-installer (pulled in by
mglaman/phpstan-drupal); setup.sh now pre-authorises that plugin and the
phpcodesniffer installer before the require, and only prints success when the
require actually succeeds. Running make check on the site-only cms install also surfaced a Makefile gap:
the lint, stan, test, and twig-lint targets (and the fix variants) did not
guard a missing web/modules/custom, which a site-only project does not have
until a module is added, so they hard-errored (phpcs exit 3). Those targets now
skip cleanly when the module directory has no files, matching the
spell/lint-js/lint-css targets and the ci.yml guards. With that fix, make check
runs clean on the site-only cms install: every quality target skips gracefully,
since a site-only project has no custom module to lint. Still pending for full
verification: the dev-tooling composer require completing on a cms project (it
was interrupted by the allow-plugins block, now fixed but not yet re-run to
success), make check exercising phpcs/phpstan against a real module in module
mode. The a11y job's URL set is now derived at runtime to match the installed
site, which fixed the false /search and /node/1 load failures the first cms
push produced. That push also surfaced a genuine WCAG link-name violation on
the Drupal CMS starter front page (the branding home link has no accessible
name): this is a real issue in Drupal CMS's own theme output, not a template
defect, and is deliberately left to fail rather than suppressed, so a cms site
built from this template needs that home link given an accessible name before
its a11y job passes.

Stage 10, custom code workspace plus optional theme: DONE at the tokeniser and
tooling level (2026-08-06). Single-module scoping is generalised into
LINT_PATHS ("web/modules/custom web/themes/custom"), mirrored across the
Makefile, phpcs.xml.dist, phpstan.neon, package.json, and ci.yml (job-level env
var). Every Makefile quality target and every ci.yml tool step iterates over the
list and keeps its "no files, skipping" guard; setup.sh and ci.yml mkdir -p both
paths so bare phpcs/phpstan runs work on a project that has only modules or only
a theme. Prettier and cspell gained --no-error-on-unmatched-pattern and
--no-must-find-files respectively, both verified locally against prettier 3.9.6
and cspell 9.8.0, so a second glob with no matches cannot fail a run that
previously passed. init.sh gained optional theme prompts after the module
prompts, with new tokens THEME_NAME, THEME_LABEL, THEME_PATH, DRUPAL_FLAVOUR and
composed tokens THEME_INTRO, THEME_LINE, THEME_LAYER. New Makefile targets:
subtheme (guard-theme-name plus an already-exists guard; localgov_base's
create_subtheme.sh on the localgov flavour, core's generate-theme starterkit on
vanilla and cms) and component (drush generate single-directory-component).
AGENTS.md gained an SDC section under Front-end Standards. The regression suite
now covers all four module/theme combinations and passes 385/385.

Live verification (2026-08-06, localgov 11, theme-only project): setup.sh
completed, make subtheme created the localgov_base subtheme at
web/themes/custom/<name> through ddev exec, and the theme enabled and became
the default theme (drush theme:enable plus config:set system.theme default).
The generator's prompt order was confirmed from localgov_base 2.x's
create_subtheme.sh itself: full name first, then machine name, writing to
../../custom/<name>, exactly what the Makefile pipes. make component
NAME=test_card then scaffolded components/test_card/ inside the theme.
drush's --answer ordering for the SDC generator was confirmed live
(theme machine name, component name, component machine name, then description,
library dependencies, CSS, JS, props, slots), so the target now pre-fills the
first three instead of printing them for the user to type.

Still not run live: core's generate-theme starterkit call on the vanilla and
cms branches (the localgov branch is now proven).

Found during that run, on a freshly scaffolded localgov_base subtheme:
make lint (phpcs) and make test pass, make twig-fix and make format clean up
what make twig-lint and make format-check flag in the generated templates, and
cspell reports 21 issues that are ordinary subtheme vocabulary (favicons,
msapplication, mstile, xlink, evenodd, linecap, miterlimit, focusable,
ckeditor, subtheme, colour/colours) plus names from the shipped logo.svg
metadata. A theme project therefore needs those words added to
.cspell-project-words.txt before make check is green; that dictionary is
deliberately left untouched here rather than pre-loaded with another project's
vocabulary. make stan remains blocked by the pre-existing
ddev-exec/PHPStan exit-code caveat below, which Stage 10 makes reachable on
theme-only projects for the first time.

Remaining open work: a handful of DDEV/composer/npm spin-ups remain marked
"needs live verification": the cms flavour full spin-up, the a11y CI job on
real GitHub Actions infrastructure, the site-only mode full spin-up, make
subtheme on the vanilla and cms branches (the localgov branch is verified),
and make lint-js/lint-css plus the GitHub Actions eslint/stylelint steps
against a live web/core frontend install.

The `make stan` spurious-exit-1 caveat is narrowed but not fixed (2026-08-06).
Measured inside the container, phpstan writes its exit code as 0 to a file, so
the analysis itself succeeds; `ddev exec vendor/bin/phpstan analyse <path>`
still reports exit 1 to the host whenever phpstan's output streams back out of
the container, and returns 0 only when that output is redirected inside the
container. Adding --no-progress does not change it, and a shell wrapper does
not either, so the earlier "works through a shell wrapper" note was too
optimistic. The run also surfaces phpstan's "These files are included multiple
times" warning, because phpstan.neon includes phpstan-drupal's neon files
explicitly while phpstan/extension-installer (pre-authorised by setup.sh since
Stage 5) registers them too. Dropping the explicit includes block was tried and
rejected: it breaks the parameters.drupal schema. Both belong to the same
follow-up.

Stage 11, local dev recipes: DONE (2026-08-06). Two new recipes
(recipes/site_tools: admin_toolbar, twig_tweak, eca, eca_ui, bpmn_io;
recipes/dev_tools: devel, environment_indicator,
environment_indicator_toolbar; ctools required by composer but deliberately
left out of both install lists, documented in site_tools' recipe.yml
description), two new local-only templates (assets/settings.local.php with
Twig debug on, render/page/dynamic_page_cache forced to NullBackend, and
config_exclude_modules excluding devel and environment_indicator_toolbar from
export; assets/development.services.yml), setup.sh wiring to copy both
templates, enable the settings.local.php include, apply both recipes after
install, and re-export config, and a `make recipe` target all landed and were
proven end to end against a real throwaway localgov 11 project
(module recipe_smoke) spun up from the template via ./scripts/init.sh and
./scripts/setup.sh with Docker/DDEV on this machine. Composer resolved
cleanly: drupal/eca to 3.1.4 and drupal/bpmn_io to 3.0.6, both on the version
lines expected for a Drupal 11 install (^3.1 / ^3.0). Twig debug confirmed
live (`$twig->isDebug()` returns `bool(true)`), and all three cache bins
(render, page, dynamic_page_cache) confirmed as
`Drupal\Core\Cache\NullBackend`. config_exclude_modules confirmed working by
inspecting the actual exported sites/default/files/sync/core.extension.yml:
admin_toolbar, admin_toolbar_tools, bpmn_io, eca, eca_ui,
environment_indicator and twig_tweak are present; devel and
environment_indicator_toolbar are correctly absent (note: `drush config:get
core.extension module` alone is not a valid check here, since it reads active
config, where devel and environment_indicator_toolbar are of course still
enabled; only the exported sync file reflects the exclusion). The environment
indicator itself renders correctly, but only for authenticated users on an
admin-toolbar page; the front page of a fresh localgov install 302-redirects
anonymous visitors to /user/login, and the toolbar markup
(`toolbar-item-environment-indicator`, `environment-indicator-settings`, the
configured "Local" name and #0b6623 colour) only appears once logged in, so
verification needed drush uli plus a cookie-jar curl rather than a bare
anonymous request to the front page.

Two real bugs were found in the throwaway copy during this live verification:

1. Staging the throwaway copy under $TMPDIR (as the verification task's own
   script suggested) silently breaks on this machine because its Docker
   provider is Colima, which by default only mounts $HOME into its VM; a
   project staged under /var/folders/... is invisible to the VM, so DDEV warns
   "/mnt/ddev_config is not mounted" and the container's
   web/sites/default/files ends up as a phantom root-owned directory the
   unprivileged container user cannot write to, failing the site install
   outright ("the directory ... is not writable"). Worked around by staging
   under $HOME instead. This is a host/Colima fact, not a template bug, but
   is worth a note anywhere this repo tells someone to stage a throwaway copy
   under $TMPDIR on a Colima-based Docker setup.
2. `scripts/setup.sh` called `ddev drush recipe recipes/site_tools -y` and
   `... recipes/dev_tools -y` with a path relative to the project root, but
   `ddev drush`'s actual PHP-level working directory is the docroot
   (web/), not the project root (`ddev exec pwd` returns /var/www/html;
   `ddev drush ev 'echo getcwd();'` returns /var/www/html/web). Both recipe
   applications therefore always failed with "The supplied path
   recipes/site_tools is not a directory" and setup.sh only warned and
   continued, so every fresh project built from this template silently skipped
   both recipes unless someone noticed the warning and applied them by hand.
   Fixed in commit 8f8a140: both calls now use `../recipes/site_tools` and
   `../recipes/dev_tools` (relative to the docroot); both applied cleanly with
   that path (site_tools installed admin_toolbar, twig_tweak, eca, eca_ui,
   bpmn_io, modeler_api; dev_tools installed devel, environment_indicator,
   environment_indicator_toolbar). A final-review pass re-checked the fix on
   its own and found it correct with no new breakage. The `make recipe`
   Makefile target had the identical defect (same docroot-relative-cwd cause)
   and was fixed alongside it in the same review pass, changing its `ddev
   drush recipe $(R)` call to `ddev drush recipe ../$(R)` while leaving the
   documented `make recipe R=recipes/site_tools` usage unchanged.

A final-review pass also found that the Twig debug confirmation above is
narrower than it looks. `$twig->isDebug()` returning `true` was real, but it
was confirmed only on the `localgov` flavour, and it works there because
`drupal/localgov_project`'s own scaffolded `web/sites/development.services.yml`
already sets `twig.config: { debug: true, ... }` by itself, independent of
this feature. Both `drupal/core-recommended` (and, by extension, `drupal/cms`,
which is core-based) and `drupal/localgov_project` scaffold their own
`web/sites/development.services.yml` during `composer install`, well before
setup.sh's later "Local development settings" section runs its
`[ ! -f web/sites/development.services.yml ]` check, so that check almost
always finds a file already in place and skips copying this feature's own
`assets/development.services.yml`. Vanilla core's own scaffolded file has no
`twig.config` override at all, so Twig debug is very likely NOT active on the
`vanilla` and `cms` flavours; this was never live-tested (only `localgov`
was). setup.sh now verifies this directly rather than trusting the
created/already-present message: after the copy-if-absent step it greps
whichever `web/sites/development.services.yml` ended up in place for
`debug: true` and warns if it is not found. This feature's
`assets/development.services.yml` and its copy-if-absent logic should be
treated as a fallback for distributions that do not already ship their own
file, not as a guarantee that Twig debug is on. Vanilla and cms still need a
live check to confirm the actual behaviour.

## Start prompt

You are maintaining the localgov-drupal-dev-template repo. Do not change
anything yet.

1. Read README.md, TEMPLATE.md, scripts/init.sh, scripts/setup.sh,
   scripts/install-drupal, the Makefile, and .github/workflows/ci.yml.
2. Confirm back to me: the current token list, the setup.sh spin-up steps in
   order, and which flavour/version combinations are wired up.
3. Give me a short prioritised backlog of improvements you would suggest (for
   example: add the Drupal CMS flavour, pin the drupal-reviewer and skill
   versions, run the remaining live verifications). Flag anything currently
   untested.

Follow the project conventions: no em dashes, keep all three flavours and both
Drupal versions working, keep all four module/theme combinations working, and
run scripts/test-template.sh before calling any template change done.
