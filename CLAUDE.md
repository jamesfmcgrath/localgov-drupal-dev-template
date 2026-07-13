# Drupal Development Guidelines

This is a Drupal 10/11 project, the `{{MODULE_NAME}}` module for {{CLIENT}}. Follow these guidelines when working on Drupal code.

## Project Context

- **Module:** `{{MODULE_PATH}}/`
- **DDEV:** `{{DDEV_NAME}}` at `{{DDEV_URL}}` (PHP 8.3, nginx-fpm)
- **Stack:** Drupal 10.2+, LocalGov Drupal (LGD)
- **Do not use git worktrees**, work directly in the repo on the feature branch

## DDEV

Run all commands via DDEV from the repo root:

```bash
ddev drush <command>
ddev composer <command>
```

Never run `drush`, `php`, or `composer` directly outside DDEV, PHP versions will not match.

## Research-First

**Before writing custom code:** check drupal.org for existing contrib modules, and check whether a LocalGov module already covers it. Prefer contrib over custom.

## Code Standards

- **PHP 8.3**: constructor property promotion, typed properties, `declare(strict_types=1)` in every file
- **PHP Attributes**: `#[Block(...)]` style for plugins, not `@Block` annotations
- **Dependency injection**: never `\Drupal::service()` in classes; inject via constructor
- **Config schema**: required for all custom configuration (`config/schema/`)
- **`final` classes**: prefer `final` on service and form classes unless extension is required
- Add cache metadata to render arrays (`#cache`: tags, contexts, max-age)
- Use `#plain_text` or `Xss::filterAdmin()` for user content; never raw `#markup` with unsanitised input
- Parameterised queries only; never concatenate user input into SQL
- API keys: store in Key module entities, never in plain config

## Drupal AJAX Form Pattern

When a form class injects a service used in an AJAX callback:

- The injected service property **must be `protected`** (not `private`/`readonly`) so `DependencySerializationTrait::__sleep()` can detect it. `private` properties are invisible to `get_object_vars()` from the parent scope.
- **Never override `__sleep()`**, the trait handles serialization once visibility is correct.
- AJAX callbacks must **build their result element directly** on `$form` before returning it; do not rely on `$form_state->setRebuild(TRUE)` inside the callback.

## Agent Resources

Use these proactively, do not wait to be asked.

- **drupal-localgov** (skill), Drupal 10/11 and LocalGov workflows: modules, theming, site building, ops. Use whenever a task touches Drupal.
- **drupal-expert** (skill), Drupal API, hook usage, architecture decisions before writing non-trivial code.
- **ddev-expert** (skill), DDEV container, config, or service troubleshooting.
- **drupal-reviewer** (agent), **run after writing or modifying any Drupal PHP file.** Catches security, DI, and render-escaping issues PHPCS will not.

Install once via `./scripts/setup.sh` (see README).

## Working Rules

- Work incrementally: small, self-contained changes, tested as you go.
- Any PHP change ships with PHPUnit tests confirming correct behaviour; run the module test suite plus `phpcbf` then `phpcs` before considering a change done.
- No em dashes in output. No code comments unless essential.
