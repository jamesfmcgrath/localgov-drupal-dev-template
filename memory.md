# Project memory: localgov-drupal-dev-template

Last updated: 2026-08-05

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
- Usage modes: module mode (module name given) and site-only mode (blank
  module name). Both must keep working.

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

## Open items / needs live verification

- cms flavour live run (2026-08-05): composer create-project and the recipe
  install both work. Fixed: setup.sh now pre-authorises
  phpstan/extension-installer (Drupal CMS blocks it via a stricter
  allow-plugins allowlist). Also fixed: Makefile lint/stan/test/twig-lint now
  skip when web/modules/custom has no files (site-only projects), instead of
  hard-erroring. Site-only cms install boots and make check runs clean (targets
  skip). Still pending: dev-tooling require completing on a cms project, make
  check against a real module (module mode), and the a11y /search URL.
- a11y CI job on real GitHub Actions infrastructure (only YAML-checked so far).
- Site-only mode full DDEV/composer spin-up.
- make lint-js / lint-css and the GitHub Actions eslint/stylelint steps
  against a live web/core frontend install.
- `make stan` can report a spurious exit 1 with zero real errors
  (ddev-exec/PHPStan interaction); not yet root-caused or fixed in the
  Makefile.

## Conventions (hard rules)

- No em dashes anywhere.
- Scripts stay executable, committed 100755.
- Only UPPER_SNAKE names wrapped in double curly braces are tokens; GitHub
  Actions ${{ }} expressions must never be touched.
- Run scripts/test-template.sh before calling any template change done.
- Keep all flavours, both Drupal versions, and both usage modes working.
