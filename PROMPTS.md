# Maintenance prompts and status

Staged Claude Code prompts for improving this template, with current status.
Run open stages from the repo root unless noted. Companion to PROJECT.md,
which holds the Claude Project instructions.

Shared conventions (repeated so they survive pasting into a fresh session):
no em dashes anywhere; scripts stay executable (100755); run
scripts/test-template.sh before calling a script change done; keep all
flavours and supported Drupal versions working; only {{UPPER_SNAKE}} names
are template tokens and GitHub Actions ${{ }} expressions must never be
touched.

## Status (2026-07-29)

- Stage 1, reviewer gates upstreamed to the skill fork: DONE
  (jamesfmcgrath/drupal-agent-resources commit 1dc398c; setup.sh fetches from
  the configured fork since 1dfdf84; the tracked .claude/agents/ copy here is
  canonical either way).
- Stage 2, agr.lock policy: DONE (generated per created project, not tracked
  in the bare template; 4e9b725 and 45197f7).
- Stage 3, pa11y-ci accessibility CI job: COMMITTED (cf8b138), needs live
  verification in the first created project that pushes with composer.json
  present (the guard job skips it on the bare template).
- Stage 4, twig-cs-fixer plus vanilla flavour live run: DONE (ef05436;
  vanilla + Drupal 11 verified end to end, three setup bugs found and fixed).
- Stage 5, Drupal CMS flavour: OPEN (prompt below).
- Stage 6, template regression suite: DONE. scripts/test-template.sh, wired
  into CI as the "template" job (runs when the guard job's composer.json
  check is false).
- Stage 7, optional module (site-only mode): DONE. init.sh, setup.sh, and the
  Makefile all support a blank module name; scripts/test-template.sh gained a
  site-only regression check. The DDEV/composer spin-up still needs a live
  run.
- Stage 8, drupal.org pipeline parity: DONE. assets/module.gitlab-ci.yml,
  make module-ci, and local parity targets (spell, lint-js, lint-css) landed;
  see PROJECT.md for the SKIP_TWIG_CS_FIXER and hex-color caveats
  found during implementation. The DDEV/npm spin-up for lint-js/lint-css
  still needs a live run.
- Vanilla + Drupal 10 live run: DONE (2026-07-29; site installs and boots on
  Drupal 10.6.14, both vanilla setup bugs from Stage 4 hold fixed, make check
  passes: phpcs/phpunit/twig-cs-fixer clean, empty module test suite skips as
  expected. Caveat: `make stan` can report a spurious exit 1 with zero real
  phpstan errors, a ddev-exec/PHPStan process-exit interaction, not specific
  to Drupal 10 or vanilla; confirmed the identical command exits 0 when run
  through a shell wrapper. Not yet root-caused or fixed in the Makefile).

---

## Stage 5: Add a Drupal CMS flavour

```
Add "cms" as a third Drupal flavour alongside localgov and vanilla, installing
Drupal CMS (composer project drupal/cms). Facts to build on, verified 2026-07:
Drupal CMS 2.1.x is Drupal core 11 only; it installs headlessly with
drush site:install recipes/drupal_cms_starter -y (the profile argument takes a
recipe path); interactive installs use its own drupal_cms_installer profile.

1. scripts/init.sh:
   - Flavour prompt becomes "localgov, vanilla or cms" (default localgov).
   - For cms: skip or ignore the version prompt and force VERSION=11 with a
     printed note (Drupal CMS is 11-only); set DRUPAL_TYPE=drupal11,
     COMPOSER_PROJECT=drupal/cms, INSTALL_PROFILE=recipes/drupal_cms_starter.
   - Do not change behaviour for the other two flavours.
2. scripts/setup.sh and scripts/install-drupal:
   - Confirm the drush site:install call passes {{INSTALL_PROFILE}} through
     unquoted-path-safe so a recipe path works as the argument.
   - In install-drupal's interactive profile picker, add a "Drupal CMS starter
     (recipe)" option that maps to recipes/drupal_cms_starter, shown only when
     the recipes/drupal_cms_starter directory exists in the docroot project.
   - Drupal CMS scaffolds a web/ docroot like recommended-project; verify
     setup.sh's copy step needs no change, and say so explicitly.
3. Docs: README.md (flavour list, tokens table example), TEMPLATE.md (flavour
   notes: cms forces Drupal 11, INSTALL_PROFILE holds a recipe path for this
   flavour), PROJECT.md (template contents and "keep flavours working" line
   now covers three flavours).
4. Smoke-test per PROJECT.md rules: throwaway copy, run init.sh choosing cms,
   check VERSION was forced to 11, INSTALL_PROFILE substituted to
   recipes/drupal_cms_starter, no leftover {{UPPER_SNAKE}} tokens, ${{ }}
   expressions intact, bash -n on scripts, make -n parses, executable bits
   kept. The composer/DDEV spin-up needs a live run; mark it so.
5. Sanity note to include in your summary: LocalGov and Drupal CMS are separate
   assemblies; cms flavour must not pull the localgov profile or modules, and
   the drupal-localgov skill's LocalGov guidance stays dormant on cms projects
   (it detects LocalGov from composer.json).
6. If scripts/test-template.sh exists (Stage 6), add the cms 11 combination to
   its COMBOS list with the expected derived values.
No em dashes. Keep all three flavours and both Drupal versions (for the two
that support 10) working.
```

---

## Stage 6: Template regression suite (protects all future updates)

```
The template repo has no automated tests: the CI guard job skips every job on
the bare template (no composer.json), and template changes are only protected
by the manual smoke-test convention in PROJECT.md. Automate that convention.

1. Create scripts/test-template.sh (tracked, mode 100755). It must:
   - Define a COMBOS list at the top, one entry per supported flavour/version
     pair with the expected derived values, currently:
       localgov 11 -> drupal11, drupal/localgov_project, localgov
       localgov 10 -> drupal10, drupal/localgov_project:^3.0, localgov
       vanilla  11 -> drupal11, drupal/recommended-project:^11, standard
       vanilla  10 -> drupal10, drupal/recommended-project:^10, standard
     (Add cms 11 here when the Stage 5 flavour lands; keep this list the single
     place a new flavour registers its expectations.)
   - For each combo: copy the repo to a fresh temp dir (exclude .git and any
     _to_delete), pipe scripted answers into ./scripts/init.sh with module name
     regress_mod, all other prompts defaulted except flavour and version.
   - Assert, per combo, with clear pass/fail output and a nonzero exit on any
     failure:
     a. init.sh exits 0; scripts/init.sh and TEMPLATE.md removed themselves.
     b. No {{UPPER_SNAKE}} tokens remain anywhere except PROJECT.md (which
        documents the token convention as literal text).
     c. The count of ${{ occurrences in .github/workflows/ci.yml is unchanged
        from before init ran.
     d. AGENTS.md, Makefile, agr.toml, .claude/settings.local.json.dist, and
        .claude/commands/a11y-check.md contain the substituted values
        (regress_mod and the combo's derived DRUPAL_TYPE, COMPOSER_PROJECT,
        INSTALL_PROFILE where each applies).
     e. bash -n passes on scripts/setup.sh and scripts/install-drupal; both
        are still executable.
     f. make -n help parses; the settings dist parses as JSON; ci.yml and
        .ddev/config.yaml parse as YAML (python3 -c with json/yaml, or
        equivalent available on the runner).
   - The suite must not touch the network, run composer, or start DDEV. It
     tests the tokeniser and file invariants only; the live spin-up remains a
     manual verification step.
2. Wire it into CI as a "template" job in .github/workflows/ci.yml that runs
   ONLY on the bare template, the inverse of the existing guard:
   if needs.guard.outputs.run == 'false'. Created projects (composer.json
   present) skip it and run the existing jobs instead; the bare template
   finally gets a green, meaningful CI run.
3. init.sh: add scripts/test-template.sh to the files it removes at the end,
   next to TEMPLATE.md, so created projects do not carry the suite. Update the
   test itself to assert the removal happened (part of check a).
4. Docs: README.md (What you get, one line on the regression suite),
   PROJECT.md (template contents; replace the manual smoke-test wording in
   Working Rules with "run scripts/test-template.sh before calling a template
   change done", keeping the DDEV/composer "needs live verification" caveat;
   update Status).
5. Verify by running scripts/test-template.sh yourself before committing, and
   also break it on purpose once (reintroduce a fake {{TOKEN}} in Makefile,
   confirm the suite fails, revert) so the failure path is proven, not assumed.
No em dashes. Scripts stay 100755. GitHub Actions ${{ }} expressions untouched
except where the new job legitimately uses them.
```

---

## Stage 7: Make the module optional (site-only mode)

```
Make the custom module optional at init time. Two usage modes:
site-only (just spin up a Drupal or LocalGov site) and module mode (current
behaviour, developing a module against the site). Module mode must not change.

1. scripts/init.sh:
   - The module name prompt becomes optional: "Module machine name (blank for
     a site-only project)". Blank selects site-only mode; a name selects
     module mode exactly as today.
   - In site-only mode: skip the module label, path, and repo prompts
     entirely. Substitute the module tokens with values that keep every file
     valid: MODULE_NAME empty, MODULE_PATH web/modules/custom (the directory,
     so quality tooling scopes to all future custom modules), MODULE_REPO
     empty. Derive nothing else differently; flavour and version work as
     today.
   - Print a closing note in site-only mode: to add a module later, create it
     under web/modules/custom/ and set MODULE in the Makefile.
2. scripts/setup.sh: guard every module-specific step (clone, drush en) so a
   blank module name skips them silently with one informational line. The
   site install itself must be identical in both modes.
3. Makefile: with MODULE set to web/modules/custom, test/lint/stan/twig
   targets operate on the whole custom modules directory, which is correct
   for both modes; the module git targets (mod-log, mod-status, mod-fetch,
   mod-branch, tag, switch, mr) and the enable target must detect a
   site-only setup (MODULE has no repo of its own or no module name) and
   exit with a clear "site-only project" message instead of failing
   confusingly.
4. phpcs.xml.dist, phpstan.neon, package.json, .github/workflows/ci.yml,
   .claude/settings.local.json.dist, .claude/commands/a11y-check.md, and
   AGENTS.md: verify each stays valid and sensible when MODULE_PATH is
   web/modules/custom and MODULE_NAME is empty. The ci.yml phpunit step and
   the twig step already guard on directory contents; confirm the phpcs and
   phpstan steps tolerate an empty or module-free web/modules/custom (skip
   with a message rather than erroring on "no files to scan"). Reword the
   a11y-check page-selection line so it reads naturally when no module name
   is present.
5. AGENTS.md project context: in site-only mode the Module line should read
   as "none yet, site-only project" rather than an empty backtick pair.
   Handle this in init.sh (conditional substitution), not by hand.
6. Regression cover: scripts/test-template.sh (Stage 6) gains a site-only
   variant for at least one flavour/version combo, asserting init.sh exits 0
   with a blank module answer, no {{UPPER_SNAKE}} tokens remain, the Makefile
   parses, and setup.sh passes bash -n. If Stage 6 has not run yet, note that
   this requirement moves into its COMBOS design.
7. Docs: README.md (Use it section: mention the blank-for-site-only prompt;
   What you get), TEMPLATE.md token table (MODULE_NAME "blank for
   site-only"), PROJECT.md (template contents, conventions: both modes must
   keep working from now on).
8. Smoke-test both modes per the repo conventions before calling it done:
   one throwaway init in site-only mode and one in module mode, checking the
   usual invariants (tokens, ${{ }}, bash -n, make -n, executable bits).
No em dashes. Scripts stay 100755.
```

---

## Stage 8: drupal.org (git.drupalcode.org) pipeline parity

```
Modules developed with this template are pushed to git.drupalcode.org, where
the official gitlab_templates pipeline runs. Make sure a module that passes
locally also passes there, and ship a ready pipeline file for module repos.

0. Read the official docs first and treat them as authoritative over this
   prompt (the job list changes over time):
   https://project.pages.drupalcode.org/gitlab_templates/ (setup page and
   jobs page). As of 2026-07 the default validation jobs include
   composer-lint, cspell, eslint, stylelint, phpcs, and twig-cs-fixer, with
   phpunit and nightwatch as default test jobs; phpstan and variant testing
   (previous/next minor/major, max PHP) are controlled by OPT_IN_* /
   RUN_JOB_* / SKIP_* variables. Confirm the current defaults and the
   canonical .gitlab-ci.yml include block from the setup page.

1. Ship a ready module pipeline file: assets/module.gitlab-ci.yml containing
   the canonical include block from the docs plus a commented variables
   section (OPT_IN_TEST_NEXT_MAJOR, _TARGET_PHP, the relevant SKIP_ and
   RUN_JOB_ knobs, each with a one-line comment). Add a Makefile target
   module-ci that copies it to $(MODULE)/.gitlab-ci.yml if none exists, and
   refuses with a message if one does.

2. Local parity so make check predicts the drupalcode pipeline:
   - cspell: add a cspell config and a project-words file at the template
     root, wired to a Makefile target (spell) covering $(MODULE); seed the
     words file with obvious project terms (localgov, drush, ddev).
   - eslint and stylelint: run them against $(MODULE) using Drupal core's
     configs from the spun-up site (web/core/), the same approach the
     drupalcode jobs use; Makefile targets lint-js and lint-css, both via
     ddev exec. Guard each to skip with a message when the module has no
     .js or .css files.
   - Add spell, lint-js, and lint-css to the check aggregate target.
   - Note in the summary anything the drupalcode defaults run that local
     tooling still cannot (nightwatch is expected to stay CI-only; say so).

3. GitHub Actions ci.yml: add matching cspell, eslint, and stylelint steps
   to the php or prettier job, each guarded on relevant files existing, so
   the GitHub side of a project repo enforces the same standards.

4. Check for conflicts: Prettier formats CSS and JS in this template; core's
   eslint and stylelint configs are Prettier-aware, but verify on a sample
   file that prettier --write output passes both linters, and reconcile
   (adjust prettier config or scope) if not.

5. Docs: README.md (What you get: drupal.org pipeline parity and the
   module-ci target; Common commands table), PROJECT.md (template contents),
   AGENTS.md Working Rules line: PHP changes must pass make check, which now
   mirrors the git.drupalcode.org default pipeline.

6. Regression suite (if scripts/test-template.sh exists): assert
   assets/module.gitlab-ci.yml survives init.sh with no tokens left inside
   it if you tokenise it, or verbatim if you do not, and that make -n
   module-ci parses. Smoke-test per repo conventions either way.
No em dashes. Scripts stay 100755. GitHub Actions ${{ }} expressions and the
GitLab $ variables in the shipped pipeline file must both survive init.sh
untouched; extend the token regex checks to cover the new file.
```

---

## Vanilla + Drupal 10 live run

Requires Docker and DDEV running locally.

```
Run the vanilla + Drupal 10 live verification for this template. Work from a
throwaway copy so the template itself stays untouched.

1. Copy the repo to a temp dir (exclude .git and any _to_delete). In the copy
   run ./scripts/init.sh with: module name vanilla10_smoke, defaults for
   label, path, repo URL (blank), DDEV name, URL, client, and skill fork;
   flavour vanilla; version 10.
2. Verify the tokeniser result before spinning up: DRUPAL_TYPE=drupal10,
   COMPOSER_PROJECT=drupal/recommended-project:^10, INSTALL_PROFILE=standard;
   no leftover {{UPPER_SNAKE}} tokens outside PROJECT.md; ${{ }} expressions
   intact in ci.yml; setup.sh and install-drupal still executable; init.sh
   and TEMPLATE.md removed themselves.
3. Run ./scripts/setup.sh and let it do the full spin-up. Watch specifically
   for the two vanilla bugs fixed on the Drupal 11 run holding here too:
   drush/drush gets installed (vanilla does not bundle it) and the
   dev-tooling composer require resolves with -W against
   drupal/recommended-project:^10.
4. Confirm the site is actually up: ddev drush status reports Drupal 10.x
   with a successful database bootstrap, and the front page returns 200.
5. Run make check in the spun-up project to prove the quality toolchain on
   Drupal 10 (phpcs, phpstan, phpunit, twig-lint). Empty module test suites
   may skip; report that as skipped, not green.
6. Report pass/fail per phase. If Docker or DDEV is unavailable, stop after
   step 2 and say the spin-up still needs a live run. Do not claim success
   you did not observe.
7. On a full pass, in the REAL repo (not the throwaway): update PROJECT.md's
   Status section to record vanilla + Drupal 10 verified with today's date
   and drop its "not yet live-run" caveat, and update the matching line in
   the Status section of PROMPTS.md. If scripts/test-template.sh exists,
   confirm the vanilla 10 combo is present in COMBOS.
8. Clean up: ddev delete -Oy the test project and remove the temp dir.
No em dashes.
```
