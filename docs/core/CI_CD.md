# CI/CD Pipeline

GitHub Actions. Four workflows:

| Workflow | File | Runs on |
| --- | --- | --- |
| Flutter CI (Strict) | `.github/workflows/flutter-ci.yml` | PRs to `main`, pushes to `main` |
| Security Audit | `.github/workflows/security.yml` | PRs, pushes to `main`, weekly |
| Supabase CI | `.github/workflows/supabase.yml` | PRs to `main`, pushes to `main` |
| Deploy Web | `.github/workflows/deploy_web.yml` | after CI passes on `main` |

## Shared setup

The Flutter SDK version is pinned in **one** place:
`.github/actions/setup-flutter/action.yml`. Every job uses that composite action,
which installs the SDK, restores the pub cache and runs `flutter pub get`. Bump
the version there to upgrade the toolchain, so the resulting churn lands in a
reviewed diff instead of arriving with whatever Flutter shipped that week.

All third-party actions are pinned to commit SHAs, with the tag in a trailing
comment. A mutable tag is a supply-chain hole.

## Why no `paths:` filters

GitHub evaluates `paths` / `paths-ignore` against only the **first 300 files** of a
diff. A pull request larger than that matches nothing, and the workflow does not
run at all — silently, with no skipped-job marker to notice.

That is not hypothetical here: the PR removing the committed `server/public`
bundle changed 568 files, so every gate in this pipeline was skipped and the PR
showed no Actions checks whatsoever. A filter that disables CI on the largest
changes is worse than no filter, so the triggers are unfiltered.

The cost is that docs-only pull requests still run the full pipeline. The fix is
to skip at the **job** level using a changed-files check that is not capped at
300 files (a `git diff` step, or `dorny/paths-filter`); both workflows carry a
`TODO` to that effect.

## Flutter CI jobs

**`static-checks`**
- `dart format . --output=none --set-exit-if-changed`
- `flutter analyze`
- `ci/policy/check_new_code.sh` — no `print()`, no unlabelled `TODO`
- `ci/policy/check_codegen.sh` — generated files updated alongside their sources
- `ci/policy/check_lockfile.sh` — `pubspec.yaml` never changes without `pubspec.lock`
- `dependency-review-action`, failing on high severity

**`unit-tests`** — sharded 4 ways (`--total-shards` / `--shard-index`), each shard
writing its own `coverage/lcov-N.info`. `fail-fast: false`, so one broken shard
does not hide the state of the others.

**`coverage`** — merges the shard files and enforces the gates:
- `ci/scripts/merge_coverage.sh` merges with `lcov -a`. Concatenating lcov files
  would double-count lines covered by more than one shard.
- `ci/scripts/check_coverage_floor.sh` enforces `ci/coverage-floor.txt`. Below the
  floor fails. More than 1 point above it warns, asking you to raise the floor —
  that ratchet is what stops coverage sagging against a fixed threshold forever.
- `diff-cover` requires **80%** coverage on changed lines (PRs only).

**`web-build`** — `flutter build web --release`, then the bundle-size budget in
`ci/budgets.json`.

**`web-smoke`** / **`web-e2e`** — Playwright against the built bundle.

**`pr-report`** — posts a single updating summary comment. It reads
`artifacts/coverage/lcov.info` and `artifacts/coverage/diff-coverage.txt`, so the
`coverage` job's artifact name and layout are load-bearing.

## Security Audit

`osv-scanner` against `pubspec.lock` and the Node lockfiles under `ci/`, failing
the job on any known vulnerability.

This job previously ran `dart pub outdated --transitive`, which reports newer
versions, knows nothing about CVEs, and exits 0 whatever it finds — a green check
that asserted nothing. That report still runs, but only on the weekly schedule and
explicitly as information rather than a gate.

## Supabase CI

Starts a real Postgres service, seeds the roles, schemas and `auth` helper
functions that the Supabase platform normally provides, then applies every
migration in filename order. This catches SQL errors, bad references and ordering
dependencies. Re-applying is attempted afterwards and a non-idempotent set of
migrations warns rather than fails.

A separate job checks that every migration is named
`<14-digit-timestamp>_<name>.sql`, since Supabase derives apply order from it.

`supabase db lint` is deliberately absent: it needs a running local Supabase
stack, and wrapping it in `|| true` to survive without one would recreate the
placeholder this workflow replaced.

## Local usage

`scripts/verify.sh` runs the same gates as `static-checks` and the test jobs, in
the same order:

```bash
./scripts/verify.sh                # format, analyze, lockfile, tests, coverage
./scripts/verify.sh --no-coverage  # skip the slower coverage gates
```

Thresholds live in `ci/coverage-floor.txt` and in `scripts/verify.sh`; they must
match `flutter-ci.yml`.

For the web build, smoke and E2E jobs:

```bash
flutter build web --release
cd ci/smoke && npm install && npm run smoke
./run_e2e.sh
```
