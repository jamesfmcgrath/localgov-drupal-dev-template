# LocalGov Drupal dev-environment template

A starting point for working locally on a Drupal 10/11 module or site, with Claude Code and Cursor agent resources, coding standards, and DDEV wiring already set up. Built for LocalGov Drupal (council) projects, but works for any Drupal project.

## What you get

- Claude Code + Cursor agent resources installed reproducibly via [`agr`](https://github.com/kasperjunge/agent-resources): `drupal-expert`, `ddev-expert`, and `drupal-localgov` skills, plus the `drupal-reviewer` agent.
- Written coding and review standards shared across Claude (`CLAUDE.md`) and Cursor (`.cursorrules`).
- A one-shot `scripts/setup.sh` that installs the agent resources, wires `.claude/settings.local.json`, and can clone your target module into place.
- A `scripts/init.sh` that turns this template into your project by filling in a handful of tokens.

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

## Notes

- Agent resource folders (`.claude/skills/`, `.cursor/skills/`) are gitignored and reproduced by `agr` from `agr.toml` + `agr.lock`. Do not vendor copies. Tracked canonical files: `CLAUDE.md`, `.cursorrules`, `agr.toml`, `agr.lock`, `.claude/agents/`, `.claude/settings.local.json.dist`.
- The `drupal-localgov` skill is hosted in a fork of `drupal-agent-resources` (`{{SKILL_FORK}}/drupal-agent-resources`). Point `{{SKILL_FORK}}` at whichever fork you maintain.
