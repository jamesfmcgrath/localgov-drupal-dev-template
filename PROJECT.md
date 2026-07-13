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

### What the template contains

- scripts/init.sh: one-time tokeniser. Prompts for module name/path, DDEV site,
  client, skill fork, and Drupal flavour (localgov|vanilla) + version (11|10).
  Substitutes {{TOKENS}} across files, then removes itself and TEMPLATE.md. Must
  preserve file executable bits (it writes back into files rather than mv-ing a
  temp over them, and re-chmods the scripts).
- scripts/setup.sh: one-command spin-up. Installs agr skills + drupal-reviewer,
  starts DDEV, scaffolds the Drupal project (composer create into a container
  temp dir then cp -n so template files are not clobbered), composer install,
  adds dev tooling, clones the module if a repo URL was given, runs
  install-drupal, enables the module. Flags: --skip-install, --force-reviewer.
- scripts/install-drupal: profile picker (Standard/Umami/LocalGov/+Demo/
  Microsites/+Elections); accepts a profile arg or runs interactively.
- Tooling: .ddev/config.yaml (with test env), phpcs.xml.dist (Drupal +
  DrupalPractice), phpstan.neon (phpstan-drupal), PHPUnit via `-c web/core` plus
  DDEV web_environment, Prettier (package.json + .prettierrc.json), a tokenised
  Makefile, .editorconfig.
- CI: .github/workflows/ci.yml runs phpcs, phpstan, phpunit (unit+kernel,
  sqlite) and a prettier check. A guard job skips everything when composer.json
  is absent, so the bare template repo does not show a red CI run.
- Agent resources: agr.toml installs drupal-expert, ddev-expert, and
  drupal-localgov (from jamesfmcgrath/drupal-agent-resources). Standards live in
  CLAUDE.md and .cursorrules.

### Tokens (substituted by init.sh)

Prompted: MODULE_NAME, MODULE_LABEL, MODULE_PATH, MODULE_REPO, DDEV_NAME,
DDEV_URL, CLIENT, SKILL_FORK. Derived from flavour/version: DRUPAL_TYPE,
COMPOSER_PROJECT, INSTALL_PROFILE. Only {{UPPER_SNAKE}} names are tokens; GitHub
Actions ${{ ... }} expressions must be left untouched.

### Conventions

- No em dashes anywhere (use commas, colons, or restructure).
- Agent resource dirs (.claude/skills/, .cursor/skills/) are gitignored and
  reproduced by agr; do not vendor copies. Tracked: CLAUDE.md, .cursorrules,
  agr.toml, agr.lock, .claude/agents/, .claude/settings.local.json.dist.
- Scripts must stay executable and be committed as 100755.
- Keep both flavour branches (localgov, vanilla) and both versions (10, 11)
  working.

### Working rules for any change

- Before claiming a change to init.sh/setup.sh is done, smoke-test it: copy the
  template to a throwaway dir, run init.sh with sample answers, then check no
  {{UPPER_SNAKE}} tokens remain, GitHub Actions ${{ }} expressions survive,
  bash -n passes on scripts, YAML/JSON/XML parse, `make -n` parses, and the
  scripts are still executable.
- The DDEV/composer/npm spin-up cannot be fully proven without Docker; if you
  cannot run it, say so and mark it "needs live verification" rather than
  claiming success.
- State assumptions and proceed; ask only when the answer changes what you do.

### Status (2026-07)

Verified end to end on clean pulls for LocalGov + Drupal 11 and LocalGov +
Drupal 10. CI added. Vanilla flavour not yet live-run. No Twig formatting in
Prettier; functional/browser tests not in CI.

## Start prompt

You are maintaining the localgov-drupal-dev-template repo. Do not change
anything yet.

1. Read README.md, TEMPLATE.md, scripts/init.sh, scripts/setup.sh,
   scripts/install-drupal, the Makefile, and .github/workflows/ci.yml.
2. Confirm back to me: the current token list, the setup.sh spin-up steps in
   order, and which flavour/version combinations are wired up.
3. Give me a short prioritised backlog of improvements you would suggest (for
   example: verify the vanilla flavour on a live run, pin the drupal-reviewer
   and skill versions, add Twig support to Prettier, add functional-test CI with
   Chrome, add a config-managed option). Flag anything currently untested.

Follow the project conventions: no em dashes, keep both flavours and both Drupal
versions working, and smoke-test any script change (throwaway copy, run
init.sh, check no tokens remain, scripts stay executable, YAML/JSON valid)
before calling it done.
