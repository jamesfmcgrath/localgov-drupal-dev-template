# LocalGov Drupal dev-environment template

A starting point for working locally on a Drupal 10/11 module or site, with Claude Code and Cursor agent resources, coding standards, and DDEV wiring already set up. Built for LocalGov Drupal (council) projects, but works for any Drupal project.

## What you get

- Claude Code + Cursor agent resources installed reproducibly via [`agr`](https://github.com/kasperjunge/agent-resources): `drupal-expert`, `ddev-expert`, and `drupal-localgov` skills, plus the `drupal-reviewer` agent.
- Shared coding, review, and accessibility standards in a single `AGENTS.md` (read natively by Cursor and most agents; Claude Code loads it via the `@AGENTS.md` import in the `CLAUDE.md` stub).
- An accessibility audit workflow (`.claude/commands/a11y-check.md`): axe-core scan plus keyboard, reflow, and motion passes, aimed at WCAG 2.2 AA (the public sector legal floor is WCAG 2.1 AA / EN 301 549).
- A DDEV config and a one-command `scripts/setup.sh` that starts DDEV, scaffolds a Drupal project (LocalGov or vanilla, chosen at init), installs the site, adds dev tooling, and enables your module.
- PHP tooling wired to the Makefile: PHPCS (Drupal, DrupalPractice), PHPStan (phpstan-drupal), PHPUnit, Twig CS Fixer for Twig templates (Prettier does not lint Twig), plus Prettier for front-end assets.
- A GitHub Actions CI workflow (`.github/workflows/ci.yml`) running PHPCS, PHPStan, Twig CS Fixer, PHPUnit (unit + kernel), the Prettier check, and a pa11y-ci accessibility job (WCAG2AA, against an installed sqlite site) on push and pull request.
- A `scripts/init.sh` that turns the template into your project by filling in a handful of tokens.

## Requirements

- [DDEV](https://ddev.com) and Docker (required; `setup.sh` aborts without DDEV)
- git (required)
- [uv](https://docs.astral.sh/uv/) and [agr](https://github.com/kasperjunge/agent-resources) for the Claude Code / Cursor skills (recommended). Install once:

  ```bash
  # uv (macOS / Linux)
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # agr
  uv tool install agr
  ```

`setup.sh` installs the skills with `agr` when it is present and skips with a hint if not. It does not install `uv` or `agr` for you, so install those first if you want the agent resources.

## Use it

1. Create a repo from this template (GitHub: "Use this template"), then clone it.
2. From the repo root, run the initialiser and answer the prompts:

   ```bash
   ./scripts/init.sh
   ```

   It asks for the module name and path, DDEV site, client, skill fork, and the Drupal flavour (`localgov` or `vanilla`) and version (`11` or `10`). It tokenises every file, then removes itself.
3. Spin the whole environment up with one command:

   ```bash
   ./scripts/setup.sh
   ```

   This installs the agent resources, starts DDEV, scaffolds and installs the Drupal site for your chosen flavour, adds the dev tooling (PHPCS, PHPStan, PHPUnit, Prettier), clones your module if you gave a repo URL, and enables it. Use `--skip-install` to stop before installing the site.
4. Start coding: `ddev launch` to open the site, `ddev drush uli` for a login link, and open the project in Claude Code or Cursor. Run `make help` for the task list.

To reinstall or switch profile later, run `./scripts/install-drupal` (interactive menu) or `./scripts/install-drupal localgov` (direct).

## Tokens

`init.sh` replaces these placeholders. See `TEMPLATE.md` for the full list and where each appears.

| Token | Example |
|---|---|
| `{{MODULE_NAME}}` | `localgov_bus_data` |
| `{{MODULE_LABEL}}` | `LocalGov Bus Data` |
| `{{MODULE_PATH}}` | `web/modules/custom/localgov_bus_data` |
| `{{MODULE_REPO}}` | `git@git.drupal.org:project/localgov_bus_data.git` |
| `{{DDEV_NAME}}` | `lgd-bus-data-dev` |
| `{{DDEV_URL}}` | `https://lgd-bus-data-dev.ddev.site` |
| `{{CLIENT}}` | `Cumberland Council bus timetables` |
| `{{SKILL_FORK}}` | `jamesfmcgrath` |

From your flavour/version answers, `init.sh` also derives `{{DRUPAL_TYPE}}` (DDEV type, e.g. `drupal11`), `{{COMPOSER_PROJECT}}` (e.g. `localgovdrupal/localgov-project`), and `{{INSTALL_PROFILE}}` (e.g. `localgov`).

## Common commands

A `Makefile` wraps the everyday tasks (run `make help` for the full list):

```bash
make help          # List all targets
make start         # Start DDEV (also stop / restart / open / logs)
make install       # Clean install, choose a profile
make si            # Fresh LocalGov install
make enable        # Enable the module
make cr            # Clear caches
make test          # PHPUnit (also lint / lint-fix / stan)
make check         # lint + stan + test + twig-lint
make twig-lint     # Lint Twig templates (also twig-fix)
make format        # Prettier format front-end assets (also format-check)
make mod-status    # Module git status (also mod-log / mod-fetch / mod-branch)
make switch BRANCH=1.0.x     # also: make mr MR=123, make tag VERSION=1.0.0-alpha1
```

## Notes

- Agent resource folders (`.claude/skills/`, `.cursor/skills/`) are gitignored and reproduced by `agr` from `agr.toml` + `agr.lock`. Do not vendor copies. Tracked canonical files: `AGENTS.md`, `CLAUDE.md` (import stub), `agr.toml`, `.claude/agents/`, `.claude/commands/`, `.claude/settings.local.json.dist`.
- The `drupal-localgov` skill is hosted in a fork of `drupal-agent-resources` (`{{SKILL_FORK}}/drupal-agent-resources`). Point `{{SKILL_FORK}}` at whichever fork you maintain.
- `agr.lock` is not committed in this bare template, since `{{SKILL_FORK}}` is still a token and agr cannot resolve it into a lock. `scripts/setup.sh` runs `agr sync`/`agr add` on first run, after `init.sh` has substituted a real GitHub owner, which generates `agr.lock`. Commit that generated `agr.lock` in the project created from this template so skill versions are pinned for the rest of the team.
