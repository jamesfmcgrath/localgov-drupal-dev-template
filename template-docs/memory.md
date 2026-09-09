# Project memory: localgov-drupal-dev-template

Last updated: 2026-09-09 (truth pass against the tree). The previous version
was dated 2026-08-06 and was silent on Stages 12 through 14, which had
already landed on main by then; this rewrite verifies every stage-status
claim against git history and the working tree rather than carrying forward
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

- Stage 12, visual regression testing: IMPLEMENTED, NEEDS LIVE VERIFICATION.
  Landed 2026-08-10 (commit 0b62495, merged via fd6273a). The code and
  tooling are genuinely in the tree: tests/vrt/vrt.spec.mjs,
  playwright.config.mjs, scan-urls.json, the Makefile vrt/vrt-update targets,
  and the CI "browser checks" job's VRT step all exist and match what
  PROMPTS.md describes. What does not exist: tests/vrt/ has no
  __screenshots__ directory at all (checked with `find`), and no commit in
  this repo's history has ever added one, so the authoritative Linux
  baseline has never been generated or committed, and the CI job has never
  run on real GitHub Actions infrastructure. The dev-test project used for
  an earlier local live check is being abandoned as stale, so that check's
  result (screenshots generated, a real diff correctly failed the
  comparison) no longer counts as evidence for this stage.
  A future verification run has to prove three things, against a fresh test
  project: (1) a first CI run with no linux/ baseline generates one and
  uploads it as a build artifact instead of failing the job; (2) that
  baseline gets committed to the repository; (3) a second CI run, baseline
  now present, produces a green comparison with no diff.
  Known flake: a fresh LocalGov install's front page redirects anonymous
  visitors to /user/login, and the LocalGov Design System login template
  shows a randomly chosen hero photo per request, which produced a ~25%
  pixel diff twice in the earlier (now-discarded) local check. Intended fix:
  set system.site page.front to a known node path via drush in the CI job's
  node-creation step, so the front page is deterministic instead of the
  random-hero redirect target. Checked directly against
  .github/workflows/ci.yml on main (grep for page.front, system.site,
  config:set): the fix is NOT present. It is still unlanded.
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

## Open items / needs live verification (checked 2026-09-09: no commit since 2026-08-06 resolves any of these; confirmed still open by reading the intervening git history, not assumed)

- cms flavour live run: dev-tooling require completing on a cms project, and
  make check against a real module (module mode), both still pending.
- a11y CI job (axe-core) on real GitHub Actions infrastructure: still only
  YAML-checked, never run live.
- Stage 12 VRT live verification: see Stage status above. This is the
  headline open item from this pass.
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

v1.0.0 has not been tagged. PROJECT.md's release convention ties a tag to a
landed PROMPTS.md stage; blocked pending Stage 12 live verification against
a fresh test project (the dev-test project is being discarded, so nothing
currently verifies it). The only tag in the repository is `v-a11y-1`
(confirmed with `git tag -l`).

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
