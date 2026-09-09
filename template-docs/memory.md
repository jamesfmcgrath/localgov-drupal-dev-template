# Project memory: localgov-drupal-dev-template

Last updated: 2026-09-09 (truth pass against the tree, then same-day Stage 12
live verification against a fresh test project). The previous version was
dated 2026-08-06 and was silent on Stages 12 through 14, which had already
landed on main by then; this rewrite verifies every stage-status claim
against git history and the working tree rather than carrying forward
unverified prior notes. See template-docs/PROJECT.md's "Keeping status
honest" section for the rule this pass follows.

## What this is

GitHub template repo (github.com/jamesfmcgrath/localgov-drupal-dev-template).
Create a project from it, run ./scripts/init.sh (tokeniser), then
./scripts/setup.sh (one-command DDEV spin-up), and get a running Drupal or
LocalGov Drupal site ready to code in. Full detail lives in PROJECT.md;
staged improvement prompts and their status live in PROMPTS.md.

## Corrections (previous notes that were wrong, not merely stale)

- setup.sh has always scaffolded with `cp -rn` (recursive, no-clobber), not
  `cp -n`. PROJECT.md previously said `cp -n`; that was wrong from the start,
  since `cp -n` alone cannot copy a directory tree. Corrected here and in
  PROJECT.md.
- Stage 15 does not exist anywhere in this repo: no commit, no PROMPTS.md
  entry, no prompt template. An earlier review session's note that Stage 15
  had landed was wrong, not stale. There is nothing to mark as landed,
  partial, or even planned; the numbering simply stops at Stage 14.
- The axe-core accessibility scan was, until the 2026-09-09 fix landed,
  silently auditing `/user/login` rather than the front page on every fresh
  LocalGov install, because of LocalGov's anonymous-visitor redirect off
  `/`. Any earlier accessibility pass recorded against `/` (this includes
  the discarded dev-test project's local checks) is evidence about the
  login page, not the front page, and must not be cited as an accessibility
  result for real site content. Only the 2026-09-09 live run against
  `/node/1` (via the `page.front` fix) counts as a front-page accessibility
  check.

## Flavours and versions

- localgov: Drupal 11 and Drupal 10.
- vanilla: Drupal 11 and Drupal 10.
- cms (Drupal CMS): Drupal 11 only (drupal/cms, recipe
  recipes/drupal_cms_starter). Tokeniser-level support DONE (2026-08-05);
  full spin-up still needs a live run (unchanged since 2026-08-06; no commit
  since has touched this).
- Usage modes: module and theme are independent optional prompts, so four
  combinations. Module only, theme only, both, and neither must all keep
  working.

## Custom code workspace

Quality tooling scopes to LINT_PATHS ("web/modules/custom web/themes/custom"),
not to a single module. Mirrored in five places: Makefile (LINT_PATHS),
phpcs.xml.dist (file entries), phpstan.neon (paths), package.json (globs), and
.github/workflows/ci.yml (job-level env var). Change it in all five or none.
$(MODULE) and $(MODULE_NAME) stay for enable, module-ci, and the mod-* targets;
$(THEME_PATH) stays for subtheme and component.

## Stage status, verified against the tree on 2026-09-09

Stages 1 through 11 are as previously recorded in PROMPTS.md and were not
re-audited line by line in this pass (out of scope; see PROJECT.md's
"Keeping status honest" note on scope). Stages 12 to 15 were the subject of
this pass, checked directly against git history and the working tree:

- Stage 12, visual regression testing: VERIFIED (2026-09-09). Landed
  2026-08-10 (commit 0b62495, merged via fd6273a); the front-page
  determinism fix landed 2026-09-09 on branch fix/vrt-front-page, PR #5,
  merged via e6fdfbd. Both are now live-verified end to end against a fresh
  test project (github.com/jamesfmcgrath/lgd-stage12-verify-20260909-215334,
  localgov flavour, Drupal 11, module and theme both configured), not the
  discarded dev-test project.
  What was actually observed on 2026-09-09, in order: PR #5's Actions run on
  the bare template correctly SKIPPED the php/prettier/browser-checks jobs
  (no composer.json yet) and the guard plus a "Template regression suite"
  job passed; this is recorded as skipped, not passed, and is not evidence
  the fix works. No action-resolution failures or removed-input warnings
  from the bumped majors (checkout v7, cache v6, setup-node v7,
  upload-artifact v7) in the jobs that did run; cache/setup-node/
  upload-artifact live only in the jobs that were skipped here, so this PR
  run alone did not exercise them.
  A fresh project was then created from the template, `init.sh` then
  `setup.sh` run for localgov/Drupal 11/module+theme, and the site installed
  cleanly end to end via DDEV. Once pushed (composer.json now present), the
  guard flipped and php/prettier/browser-checks all ran for real. The
  browser-checks job: created node 1, ran
  `vendor/bin/drush config:set system.site page.front "/node/1" -y`
  (confirmed in the job log), then axe-core scanned 2 pages ("/" and
  "/node/1") with 0 violations, confirming the scan hit real front-page
  content and not the /user/login redirect. The VRT spec found no
  tests/vrt/__screenshots__/linux/ baseline, generated one
  (front-page.png, node-1.png), and uploaded it as build artifact
  vrt-baselines-linux instead of failing the job. Those two PNGs were
  downloaded with `gh run download` and committed to the project repo. A
  no-op commit was then pushed to trigger a second run: its browser-checks
  job log reads "Committed Linux baselines found; comparing against them."
  followed by "2 passed" — a genuine green comparison against the committed
  baseline, not a second bootstrap. This is the proof this stage was
  waiting for; both runs passed on the first attempt, so there was no
  diff to diagnose.
  Also reconfirmed in the same pass: all nine SCAFFOLD_PRUNE artefacts
  (.github/workflows/test.yml, .gitlab-ci.yml, .gitpod.yml, .gitpod/,
  .lando.dist.yml, .lando/, .vscode/, README_FRONTEND_TOOLING.md,
  phpstan-baseline.php) were absent after setup.sh on this fresh project,
  and the template's own .github/workflows/ci.yml survived with its
  {{TOKENS}} substituted (checked directly, no {{UPPER_SNAKE}} tokens
  remain). This supersedes the e8f63eb commit message's earlier
  `--skip-install` scaffold-only check with a full site-install run.
- Stage 13, non-interactive init and dynamic token discovery: DONE. Landed
  2026-08-10 (commit 56f50ac, merged via 564d2e1, status corrected in
  fcf3775). Confirmed present in scripts/init.sh: a flag for every prompt,
  --defaults/--help, validation before the first prompt, template.answers
  written before substitution, and the grep -rlE-based discovered
  substitution list (checked directly in the script, not assumed from
  PROMPTS.md). This stage needs no live DDEV/composer verification: it is
  tokeniser-level only, already covered by scripts/test-template.sh without
  touching the network, and that suite passes today.
- Stage 14, docs split, shipped project docs, changelog: DONE. Landed
  2026-08-12, commit ce3b536, a direct commit to main (not a PR merge).
  Confirmed present in the tree: template-docs/ holds PROJECT.md, PROMPTS.md,
  and memory.md (moved from the repo root); docs/ holds getting-started.md,
  add-a-module-later.md, add-a-theme.md, recipes.md, pipeline-parity.md, and
  troubleshooting.md; CHANGELOG.md exists at the repo root. Gap this pass
  closed: ce3b536 never added its own entry to PROMPTS.md's ledger, and this
  file was never updated to mention Stages 12 through 14 at all until now.
- Stage 15: does not exist. See Corrections above.

## Verification status (stages before 12; unchanged since 2026-08-06, not re-checked by this pass except where noted)

- LocalGov + Drupal 11: verified end to end.
- LocalGov + Drupal 10: verified end to end.
- Vanilla + Drupal 11: verified end to end (2026-07-28); fixed three setup
  bugs (lowercase "standard" profile match, composer require -W, drush/drush
  install for vanilla).
- Vanilla + Drupal 10: verified end to end (first run 2026-07-29, re-run
  2026-08-05 with no issues). Installs and boots on Drupal 10.6.14, front
  page 200, make check clean.
- LocalGov + Drupal 11, theme-only project: verified end to end (2026-08-06).
- LocalGov + Drupal 11, module and theme both configured, full DDEV/composer
  site install (not --skip-install): verified end to end (2026-09-09), as
  part of the Stage 12 live verification above.

## Open items / needs live verification (checked 2026-09-09: no commit since 2026-08-06 resolves any of these; confirmed still open by reading the intervening git history, not assumed)

- cms flavour live run: dev-tooling require completing on a cms project, and
  make check against a real module (module mode), both still pending.
- a11y CI job (axe-core) on real GitHub Actions infrastructure: RESOLVED
  2026-09-09. Ran live in the Stage 12 verification above (0 violations
  across 2 pages, against real front-page content, not the login redirect).
  Only the localgov/Drupal 11/module+theme combination was exercised;
  vanilla and cms flavours have not run this job live yet.
- Stage 12 VRT live verification: RESOLVED 2026-09-09. See Stage status
  above.
- Site-only mode full DDEV/composer spin-up (site install, not just
  scaffold): still open. Note for future verification: a scaffold-and-prune
  smoke test that passes --skip-install to setup.sh does not satisfy this
  item, since it stops before the site install step this item is asking
  about.
- make lint-js / lint-css and the GitHub Actions eslint/stylelint steps
  against a live web/core frontend install: still open.
- PHP version: still 8.3 in .ddev/config.yaml (confirmed by reading the
  file). Bumping to 8.4 needs a live check that LocalGov 4.x's contrib
  dependency tree resolves and runs cleanly on 8.4 first; not attempted.

## Caveats resolved and confirmed still resolved in the tree (checked 2026-09-09)

- `make stan` spurious exit 1: phpstan.neon carries only `parameters.level`
  and `parameters.paths`, no `drupal_root` key and no explicit
  phpstan-drupal `includes:` block (confirmed by reading the file directly).
  Matches the 2026-08-10 fix; still correct.
- `make subtheme` on vanilla: Makefile prefers `vendor/bin/dr generate-theme`
  when present, falling back to the legacy `web/core/scripts/drupal` call
  otherwise (confirmed by reading the Makefile directly). Still correct.
- `make subtheme` cspell vocabulary: the Makefile still appends a
  marker-guarded, deduplicated block of generic subtheme words to
  .cspell-project-words.txt after scaffolding (confirmed by reading the
  Makefile directly). Still correct.

## Release status

v1.0.0 tagged 2026-09-09, once Stage 12 live verification (both the
scaffold prune and the VRT baseline round-trip) passed against
lgd-stage12-verify-20260909-215334. Release notes drawn from CHANGELOG.md's
former Unreleased section, now moved under the `[1.0.0]` heading. The only
other tag in the repository is `v-a11y-1` (confirmed with `git tag -l`).

## Conventions (hard rules)

- No em dashes anywhere.
- Scripts stay executable, committed 100755.
- Only UPPER_SNAKE names wrapped in double curly braces are tokens; GitHub
  Actions ${{ }} expressions must never be touched.
- Run scripts/test-template.sh before calling any template change done.
- Keep all flavours, both Drupal versions, and all four module/theme
  combinations working.
- Status claims in this file, PROJECT.md, and PROMPTS.md are checked against
  git history and the working tree before being written, not carried forward
  from a previous note or an external conversation. The tree wins over any
  document.
