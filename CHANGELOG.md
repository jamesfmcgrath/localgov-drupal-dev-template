# Changelog

All notable changes to this template are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project has
not yet cut a tagged release (see "Release convention" in
`template-docs/PROJECT.md`), so everything so far sits under Unreleased.

## Unreleased

### Added

- Non-interactive `init.sh`: every prompt has a matching flag, plus
  `--defaults` and `--help`; dynamic token discovery replaces a
  hand-maintained substitution list (Stage 13).
- Visual regression testing via Playwright (`make vrt`, `make vrt-update`),
  reusing the accessibility job's browser install (Stage 12).
- `recipes/dev_tools` and `recipes/site_tools`, `make recipe`, and local dev
  settings templates (`assets/settings.local.php`,
  `assets/development.services.yml`) applied automatically by `setup.sh`
  (Stage 11).
- Custom code workspace generalisation: quality tooling scopes to
  `web/modules/custom` and `web/themes/custom` rather than one hard-coded
  module; optional theme mode alongside the optional module, so module
  only, theme only, both, or neither all work; `make subtheme` and
  `make component` (Stage 10).
- axe-core + Playwright accessibility scan, replacing pa11y-ci, with
  runtime-derived scan URLs (Stage 9).
- drupal.org (git.drupalcode.org) pipeline parity: `assets/module.gitlab-ci.yml`,
  `make module-ci`, and local cspell/ESLint/Stylelint parity with the
  upstream pipeline's default jobs (Stage 8).
- Optional module (site-only mode): a blank module name is a fully
  supported project shape (Stage 7).
- `scripts/test-template.sh` regression suite, exercising `init.sh` across
  every flavour/version/module/theme combination, wired into CI (Stage 6).
- Drupal CMS flavour (`drupal/cms`, Drupal 11 only, the
  `recipes/drupal_cms_starter` recipe) (Stage 5).
- Twig CS Fixer (`make twig-lint`, `make twig-fix`) and a verified vanilla
  flavour live run (Stage 4).
- `agr.lock` policy: generated per created project rather than tracked in
  the bare template (Stage 2).

### Fixed

- pa11y-ci accessibility CI job committed; needs live verification on a
  project with `composer.json` present (Stage 3).

### Changed

- Claude Code / Cursor reviewer gates upstreamed to the `drupal-agent-resources`
  skill fork, so the tracked `.claude/agents/` copy and the fork stay in
  sync (Stage 1).
