# Maintenance prompts and status

Staged Claude Code prompts for improving this template, with current status.
Run open stages from the repo root unless noted. Companion to PROJECT.md,
which holds the Claude Project instructions.

Shared conventions (repeated so they survive pasting into a fresh session):
no em dashes anywhere; scripts stay executable (100755); run the regression
suite (or the manual smoke test until Stage 6 lands) before calling a script
change done; keep all flavours and supported Drupal versions working; only
{{UPPER_SNAKE}} names are template tokens and GitHub Actions ${{ }}
expressions must never be touched.

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
- Stage 6, template regression suite: OPEN (prompt below). Recommended order:
  6 before 5, so the CMS flavour lands with regression cover.
- Also open: vanilla + Drupal 10 live run (see PROJECT.md status).

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
       localgov 11 -> drupal11, localgovdrupal/localgov-project, localgov
       localgov 10 -> drupal10, localgovdrupal/localgov-project:^3.0, localgov
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
