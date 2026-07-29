# Template tokens

`scripts/init.sh` substitutes these across the files listed. Run it once, from the repo root, immediately after creating a repo from this template. It removes itself when done.

| Token | Meaning | Default / example |
|---|---|---|
| `{{MODULE_NAME}}` | Module machine name | `my_module` (blank for a site-only project) |
| `{{MODULE_LABEL}}` | Human-readable module name | `My Module` |
| `{{MODULE_PATH}}` | Path to the module in the site | `web/modules/custom/{{MODULE_NAME}}` |
| `{{MODULE_REPO}}` | Git URL of the module (for setup.sh to clone) | (leave blank to skip cloning) |
| `{{DDEV_NAME}}` | DDEV project name | `my-project-dev` |
| `{{DDEV_URL}}` | DDEV site URL | `https://{{DDEV_NAME}}.ddev.site` |
| `{{CLIENT}}` | Client / project context line | `Example Council` |
| `{{SKILL_FORK}}` | GitHub owner of the drupal-agent-resources fork hosting drupal-localgov | `jamesfmcgrath` |
| `{{DRUPAL_TYPE}}` | DDEV project type (derived from version) | `drupal11` |
| `{{COMPOSER_PROJECT}}` | Composer project to scaffold (derived from flavour/version) | `drupal/localgov_project` |
| `{{INSTALL_PROFILE}}` | Install profile (derived from flavour) | `localgov` |

## Where tokens appear

- `AGENTS.md`, project context (composed via `MODULE_INTRO`/`MODULE_LINE` so it reads naturally with or without a module), DDEV site, client (CLAUDE.md is only the @AGENTS.md import stub, no tokens)
- `.claude/commands/a11y-check.md`, DDEV site URL, page-selection wording (`MODULE_AFFECTS`)
- `scripts/setup.sh`, `MODULE_REPO`, `MODULE_PATH`, `DDEV_NAME`, `SKILL_FORK`
- `Makefile`, `MODULE_NAME`, `MODULE_PATH`, `DDEV_NAME`
- `.claude/settings.local.json.dist`, module path in the allowlist
- `agr.toml`, `SKILL_FORK` in the drupal-localgov handle
- `README.md`, examples
- `.ddev/config.yaml`, `DDEV_NAME`, `DRUPAL_TYPE`
- `phpcs.xml.dist` / `phpstan.neon`, `MODULE_NAME`, `MODULE_PATH`
- `package.json`, `PACKAGE_NAME`, `PACKAGE_DESCRIPTION`, `MODULE_PATH`
- `.github/workflows/ci.yml`, `MODULE_PATH`

## agr.lock

`agr.toml` is tracked, but `agr.lock` is not: it can't be generated correctly
until `{{SKILL_FORK}}` above is substituted with a real GitHub owner, since
the `drupal-localgov` handle depends on it. `scripts/setup.sh` runs `agr sync`
(or `agr add` if no lock exists yet) after `init.sh` has run, which writes
`agr.lock` with concrete commits pinned for `drupal-expert`, `ddev-expert`,
and `drupal-localgov`. Commit that generated file in your new project so
skill versions are pinned and reproducible for the rest of the team.

## Non-LocalGov projects

For a vanilla Drupal project, keep everything the same; the `drupal-localgov` skill detects LocalGov vs vanilla from `composer.json` and only applies council-specific guidance when relevant. If you never touch LocalGov, you can drop the drupal-localgov line from `agr.toml` and `scripts/setup.sh`.

## Site-only mode

Leave the module machine name prompt blank in `init.sh` to skip module mode entirely: no module label, path, or repo prompt, `MODULE_PATH` becomes `web/modules/custom` (so quality tooling still scopes to whatever custom modules get added later), and `MODULE_NAME`/`MODULE_REPO` stay empty. Five composed tokens, `MODULE_INTRO`, `MODULE_LINE`, `MODULE_AFFECTS`, `PACKAGE_NAME`, and `PACKAGE_DESCRIPTION`, are not prompted directly; `init.sh` derives them from `MODULE_NAME` and the other answers so AGENTS.md, `.claude/commands/a11y-check.md`, and `package.json` read naturally in both modes. To add a module later, create it under `web/modules/custom/` and set `MODULE` and `MODULE_NAME` in the `Makefile`.
