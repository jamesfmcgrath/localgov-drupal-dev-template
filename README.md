# LocalGov Drupal dev-environment template

A starting point for working locally on a Drupal 10/11 module or site, with Claude Code and Cursor agent resources, coding standards, and DDEV wiring already set up. Built for LocalGov Drupal (council) projects, but works for any Drupal project.

## What you get

- Claude Code + Cursor agent resources installed reproducibly via [`agr`](https://github.com/kasperjunge/agent-resources): `drupal-expert`, `ddev-expert`, and `drupal-localgov` skills, plus the `drupal-reviewer` agent.
- Written coding and review standards shared across Claude (`CLAUDE.md`) and Cursor (`.cursorrules`).
- A one-shot `scripts/setup.sh` that installs the agent resources, wires `.claude/settings.local.json`, and can clone your target module into place.
- A `scripts/init.sh` that turns this template into your project by filling in a handful of tokens.

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

   It fills in the module name, DDEV site, module git URL, and client across every file, then removes itself.
3. Run the environment setup:

   ```bash
   ./scripts/setup.sh
   ```

4. Install the Drupal site, choosing a profile when prompted:

   ```bash
   ./scripts/install-drupal            # interactive profile menu
   ./scripts/install-drupal localgov   # or pass a profile directly
   ```

   Profiles: Standard, Umami, LocalGov, LocalGov (with Demo Content), LocalGov Microsites, LocalGov (with Elections). It runs `ddev drush si`, exports config, clears caches, commits `config/` if present, and prints a one-time login link.

5. Start work: `ddev start` if not already running, then open the project in Claude Code or Cursor.

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
make check         # lint + stan + test
make mod-status    # Module git status (also mod-log / mod-fetch / mod-branch)
make switch BRANCH=1.0.x     # also: make mr MR=123, make tag VERSION=1.0.0-alpha1
```

## Notes

- Agent resource folders (`.claude/skills/`, `.cursor/skills/`) are gitignored and reproduced by `agr` from `agr.toml` + `agr.lock`. Do not vendor copies. Tracked canonical files: `CLAUDE.md`, `.cursorrules`, `agr.toml`, `agr.lock`, `.claude/agents/`, `.claude/settings.local.json.dist`.
- The `drupal-localgov` skill is hosted in a fork of `drupal-agent-resources` (`{{SKILL_FORK}}/drupal-agent-resources`). Point `{{SKILL_FORK}}` at whichever fork you maintain.
