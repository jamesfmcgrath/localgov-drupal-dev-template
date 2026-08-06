# Template tokens

`scripts/init.sh` substitutes these across the files listed. Run it once, from the repo root, immediately after creating a repo from this template. It removes itself when done.

| Token | Meaning | Default / example |
|---|---|---|
| `{{MODULE_NAME}}` | Module machine name | `my_module` (blank for no custom module) |
| `{{MODULE_LABEL}}` | Human-readable module name | `My Module` |
| `{{MODULE_PATH}}` | Path to the module in the site | `web/modules/custom/{{MODULE_NAME}}` |
| `{{MODULE_REPO}}` | Git URL of the module (for setup.sh to clone) | (leave blank to skip cloning) |
| `{{THEME_NAME}}` | Theme machine name | `my_theme` (blank for no custom theme) |
| `{{THEME_LABEL}}` | Human-readable theme name | `My Theme` |
| `{{THEME_PATH}}` | Path to the theme in the site | `web/themes/custom/{{THEME_NAME}}` |
| `{{DDEV_NAME}}` | DDEV project name | `my-project-dev` |
| `{{DDEV_URL}}` | DDEV site URL | `https://{{DDEV_NAME}}.ddev.site` |
| `{{CLIENT}}` | Client / project context line | `Example Council` |
| `{{SKILL_FORK}}` | GitHub owner of the drupal-agent-resources fork hosting drupal-localgov | `jamesfmcgrath` |
| `{{DRUPAL_TYPE}}` | DDEV project type (derived from version) | `drupal11` |
| `{{DRUPAL_FLAVOUR}}` | Normalised flavour (derived) | `localgov`, `vanilla`, or `cms` |
| `{{COMPOSER_PROJECT}}` | Composer project to scaffold (derived from flavour/version) | `drupal/localgov_project` |
| `{{INSTALL_PROFILE}}` | Install profile (derived from flavour) | `localgov` |

## Where tokens appear

- `AGENTS.md`, project context (composed via `MODULE_INTRO`/`MODULE_LINE`/`THEME_INTRO`/`THEME_LINE` so it reads naturally in all four module/theme combinations), DDEV site, client (CLAUDE.md is only the @AGENTS.md import stub, no tokens)
- `.claude/commands/a11y-check.md`, DDEV site URL, page-selection wording (`MODULE_AFFECTS`), theme fix-layer hint (`THEME_LAYER`)
- `scripts/setup.sh`, `MODULE_REPO`, `MODULE_PATH`, `MODULE_NAME`, `DDEV_NAME`, `DDEV_URL`, `SKILL_FORK`, `COMPOSER_PROJECT`, `INSTALL_PROFILE`
- `Makefile`, `MODULE_NAME`, `MODULE_PATH`, `THEME_NAME`, `THEME_LABEL`, `THEME_PATH`, `DRUPAL_FLAVOUR`, `DDEV_NAME`
- `.claude/settings.local.json.dist`, module path in the allowlist
- `agr.toml`, `SKILL_FORK` in the drupal-localgov handle
- `README.md`, examples
- `.ddev/config.yaml`, `DDEV_NAME`, `DRUPAL_TYPE`
- `phpcs.xml.dist`, `MODULE_NAME` (ruleset name only)
- `package.json`, `PACKAGE_NAME`, `PACKAGE_DESCRIPTION`
- `.github/workflows/ci.yml`, `INSTALL_PROFILE`

`phpstan.neon`, and the file globs in `phpcs.xml.dist`, `package.json`, and
`.github/workflows/ci.yml`, hold no path tokens: they scope to the custom code
workspace (see below), not to one module.

## The custom code workspace

Quality tooling scopes to a list of custom code paths rather than to a single
module. The default list is:

```
web/modules/custom web/themes/custom
```

It is declared as `LINT_PATHS` in the `Makefile`, mirrored as `<file>` entries
in `phpcs.xml.dist`, as `paths` in `phpstan.neon`, as globs in `package.json`,
and as a job-level `LINT_PATHS` env var in `.github/workflows/ci.yml`. Widen the
workspace by adding a path in those five places.

`make lint`, `lint-fix`, `stan`, `test`, `twig-lint`, `twig-fix`, `spell`,
`lint-js`, `lint-css`, `format`, and `format-check` iterate over `LINT_PATHS`
and skip a path that holds no matching files. The module-specific targets
(`enable`, `module-ci`, and the `mod-*` git helpers) stay scoped to `$(MODULE)`;
the theme targets (`subtheme`, `component`) stay scoped to `$(THEME_PATH)`.

`scripts/setup.sh` and CI both `mkdir -p` the workspace paths, so a bare
`vendor/bin/phpcs` or `vendor/bin/phpstan analyse` works on a project that has
only modules, or only a theme, so far.

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

## Drupal CMS flavour

Choosing `cms` at the flavour prompt scaffolds Drupal CMS (`drupal/cms`) instead of LocalGov or vanilla. Drupal CMS is Drupal 11 only, so `init.sh` forces the Drupal 11 DDEV type regardless of the version answer. For this flavour the install profile is a recipe path (`recipes/drupal_cms_starter`), not a profile machine name; `scripts/install-drupal` installs it with `drush si recipes/drupal_cms_starter`. LocalGov and Drupal CMS are separate assemblies: the `cms` flavour does not pull the localgov profile or modules, and the `drupal-localgov` skill stays dormant on a `cms` project (it detects LocalGov from `composer.json`).

## Module and theme are independent

The module and theme prompts are both optional, so all four combinations are
supported and must keep working:

| Module | Theme | Result |
|---|---|---|
| yes | yes | Module and theme both configured |
| yes | no | Module only (the original single-module mode, unchanged) |
| no | yes | Theme only, no custom module |
| no | no | Site-only project |

Leave the module machine name prompt blank to skip module mode: no module
label, path, or repo prompt, `MODULE_PATH` becomes `web/modules/custom`, and
`MODULE_NAME`/`MODULE_REPO` stay empty. Leave the theme machine name prompt
blank to skip theme mode: no theme label prompt, `THEME_PATH` becomes
`web/themes/custom`, and `THEME_NAME`/`THEME_LABEL` stay empty.

Composed tokens are not prompted directly; `init.sh` derives them from the
answers so `AGENTS.md`, `.claude/commands/a11y-check.md`, and `package.json`
read naturally in every combination: `MODULE_INTRO`, `MODULE_LINE`,
`MODULE_AFFECTS`, `THEME_INTRO`, `THEME_LINE`, `THEME_LAYER`, `PACKAGE_NAME`,
and `PACKAGE_DESCRIPTION`.

To add a module later, create it under `web/modules/custom/` and set `MODULE`
and `MODULE_NAME` in the `Makefile`. To add a theme later, set `THEME_NAME`,
`THEME_LABEL`, and `THEME_PATH` in the `Makefile` and run `make subtheme`.

## Scaffolding the theme

`make subtheme` creates the theme at `$(THEME_PATH)`. It refuses if that
directory already exists, and `guard-theme-name` refuses if no theme was
configured.

- `localgov` flavour: runs `scripts/create_subtheme.sh` from
  `web/themes/contrib/localgov_base` (the generator LocalGov Base ships), fed
  the theme label and machine name. LocalGov Base 2.x is the current branch;
  1.x bug fixes ended in December 2025.
- `vanilla` and `cms` flavours: runs Drupal core's starterkit generator,
  `php web/core/scripts/drupal generate-theme <name> --name "<label>"
  --path themes/custom`.

`make component NAME=x` wraps `drush generate single-directory-component` for
adding a single directory component to the theme.
