# Template tokens

`scripts/init.sh` substitutes these across the files listed. Run it once, from the repo root, immediately after creating a repo from this template. It removes itself when done.

| Token | Meaning | Default / example |
|---|---|---|
| `{{MODULE_NAME}}` | Module machine name | `my_module` |
| `{{MODULE_LABEL}}` | Human-readable module name | `My Module` |
| `{{MODULE_PATH}}` | Path to the module in the site | `web/modules/custom/{{MODULE_NAME}}` |
| `{{MODULE_REPO}}` | Git URL of the module (for setup.sh to clone) | (leave blank to skip cloning) |
| `{{DDEV_NAME}}` | DDEV project name | `my-project-dev` |
| `{{DDEV_URL}}` | DDEV site URL | `https://{{DDEV_NAME}}.ddev.site` |
| `{{CLIENT}}` | Client / project context line | `Example Council` |
| `{{SKILL_FORK}}` | GitHub owner of the drupal-agent-resources fork hosting drupal-localgov | `jamesfmcgrath` |

## Where tokens appear

- `CLAUDE.md`, project context, module path, DDEV site, client
- `.cursorrules`, same context block
- `scripts/setup.sh`, `MODULE_REPO`, `MODULE_PATH`, `DDEV_NAME`, `SKILL_FORK`
- `.claude/settings.local.json.dist`, module path in the allowlist
- `agr.toml`, `SKILL_FORK` in the drupal-localgov handle
- `README.md`, examples

## Non-LocalGov projects

For a vanilla Drupal project, keep everything the same; the `drupal-localgov` skill detects LocalGov vs vanilla from `composer.json` and only applies council-specific guidance when relevant. If you never touch LocalGov, you can drop the drupal-localgov line from `agr.toml` and `scripts/setup.sh`.
