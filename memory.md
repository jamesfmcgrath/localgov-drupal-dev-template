# Project memory: localgov-drupal-dev-template

Last updated: 2026-08-06

## What this is

GitHub template repo (github.com/jamesfmcgrath/localgov-drupal-dev-template).
Create a project from it, run ./scripts/init.sh (tokeniser), then
./scripts/setup.sh (one-command DDEV spin-up), and get a running Drupal or
LocalGov Drupal site ready to code in. Full detail lives in PROJECT.md;
staged improvement prompts and their status live in PROMPTS.md.

## Flavours and versions

- localgov: Drupal 11 and Drupal 10.
- vanilla: Drupal 11 and Drupal 10.
- cms (Drupal CMS): Drupal 11 only (drupal/cms, recipe
  recipes/drupal_cms_starter). Tokeniser-level support DONE (2026-08-05); full
  spin-up needs a live run.
- Usage modes: module and theme are independent optional prompts, so four
  combinations. Module only, theme only, both, and neither must all keep
  working.

## Custom code workspace

Quality tooling scopes to LINT_PATHS ("web/modules/custom web/themes/custom"),
not to a single module. Mirrored in five places: Makefile (LINT_PATHS),
phpcs.xml.dist (file entries), phpstan.neon (paths), package.json (globs), and
.github/workflows/ci.yml (job-level env var). Change it in all five or none.
$(MODULE) and $(MODULE_NAME) stay for enable, module-ci, and the mod-* targets;
$(THEME_PATH) stays for subtheme and component.

## Verification status

- LocalGov + Drupal 11: verified end to end.
- LocalGov + Drupal 10: verified end to end.
- Vanilla + Drupal 11: verified end to end (2026-07-28); fixed three setup
  bugs (lowercase "standard" profile match, composer require -W, drush/drush
  install for vanilla).
- Vanilla + Drupal 10: verified end to end (first run 2026-07-29, re-run
  2026-08-05 with no issues). Installs and boots on Drupal 10.6.14, front
  page 200, make check clean.

## Stage status (from PROMPTS.md)

- Stage 1 reviewer gates: DONE.
- Stage 2 agr.lock policy: DONE.
- Stage 3 accessibility CI job: superseded by Stage 9.
- Stage 4 twig-cs-fixer + vanilla live run: DONE.
- Stage 5 Drupal CMS flavour: DONE at tokeniser level (2026-08-05); live
  spin-up pending.
- Stage 6 template regression suite (scripts/test-template.sh): DONE.
- Stage 7 optional module / site-only mode: DONE.
- Stage 8 drupal.org (GitLab CI) pipeline parity: DONE.
- Stage 9 axe-core + Playwright a11y (replacing pa11y-ci): DONE, WCAG 2.2 AA.
- Stage 10 custom code workspace (LINT_PATHS) + optional theme: DONE at the
  tokeniser and tooling level (2026-08-06). New tokens THEME_NAME, THEME_LABEL,
  THEME_PATH, DRUPAL_FLAVOUR, plus composed THEME_INTRO, THEME_LINE,
  THEME_LAYER. New targets: subtheme, component. AGENTS.md gained an SDC
  section. Regression suite passes 385/385 across all four module/theme
  combinations. make subtheme still needs a live DDEV run.

## Open items / needs live verification

- cms flavour live run (2026-08-05): composer create-project and the recipe
  install both work. Fixed: setup.sh now pre-authorises
  phpstan/extension-installer (Drupal CMS blocks it via a stricter
  allow-plugins allowlist). Also fixed: Makefile lint/stan/test/twig-lint now
  skip when web/modules/custom has no files (site-only projects), instead of
  hard-erroring. Site-only cms install boots and make check runs clean (targets
  skip). a11y job now derives scan URLs at runtime (front page, created node by
  real id, /search only if served), fixing the false /search and /node/1 404s on
  cms. A real link-name WCAG violation in Drupal CMS's own front-page theme
  remains and is left to fail, not suppressed (a cms site must give its branding
  home link an accessible name). Still pending: dev-tooling require completing on
  a cms project, and make check against a real module (module mode).
- a11y CI job on real GitHub Actions infrastructure (only YAML-checked so far).
- Site-only mode full DDEV/composer spin-up.
- make lint-js / lint-css and the GitHub Actions eslint/stylelint steps
  against a live web/core frontend install.
- `make stan` can report a spurious exit 1 with zero real errors
  (ddev-exec/PHPStan interaction); not yet root-caused or fixed in the
  Makefile.
- make subtheme end to end on both branches. The localgov branch's piped
  answers were verified directly against localgov_base 2.x's
  create_subtheme.sh outside DDEV; the ddev exec wrapping and core's
  generate-theme call were not run.
- make component pre-filling the component name. drush's --answer ordering for
  the SDC generator could not be verified from the published docs, so the
  target runs the generator interactively and prints the answers to give.

## Conventions (hard rules)

- No em dashes anywhere.
- Scripts stay executable, committed 100755.
- Only UPPER_SNAKE names wrapped in double curly braces are tokens; GitHub
  Actions ${{ }} expressions must never be touched.
- Run scripts/test-template.sh before calling any template change done.
- Keep all flavours, both Drupal versions, and all four module/theme
  combinations working.
