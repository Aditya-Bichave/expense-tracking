# Coverage Playbook

Everything needed to measure, target, and move the coverage number on this repo.
Read this before touching `lcov.info` by hand.

## 1. The metric

Total line coverage over `coverage/lcov.info`:

```
coverage% = sum(LH) / sum(LF) * 100
```

`LF` = lines found (executable), `LH` = lines hit. Branch and function records
are emitted by the Dart VM but are **not** the project metric — do not quote
`BRF`/`BRH`.

Generate and read it:

```bash
flutter test --coverage --concurrency=8
```

```bash
awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "covered=%d total=%d pct=%.2f%%\n", lh, lf, 100*lh/lf}' coverage/lcov.info
```

Per-file, worst-first (this is the ranking input):

```bash
awk -F: '/^SF:/{f=$2} /^LF:/{lf=$2} /^LH:/{lh=$2; if(lf>0) printf "%6d %6d %6.1f%% %s\n", lf-lh, lf, 100*lh/lf, f}' coverage/lcov.info | sort -rn
```

Columns: uncovered, total, pct, file. Sorted by uncovered lines descending —
i.e. by raw upside.

## 2. What is in the denominator

`flutter test --coverage` instruments **only `lib/`**, and only files that are
transitively imported by at least one test. That has two consequences that
dominate planning here:

- **A file with no test importing it is absent from `lcov.info` entirely.** It
  contributes 0 to both `LF` and `LH`. Writing the first test for such a file
  *adds* lines to the denominator as well as the numerator — so a large,
  poorly-covered new file can push the percentage **down** even though it raises
  absolute covered lines.
- Generated code (`*.g.dart`, `hive_registrar.g.dart`, `l10n/`) is included if
  imported. It is line-heavy and mechanically covered, so it flatters the number.

**Planning rule:** prefer files already present in `lcov.info` with low `LH`.
They add numerator without adding denominator. Only pull in an absent file when
you intend to cover a large majority of it.

## 3. Targets

```
REQUIRED_LINES = ceil((TARGET_PCT - CURRENT_PCT) / 100 * TOTAL_LINES)
```

This is exact only while `TOTAL_LINES` is constant. If your batch introduces
previously-unimported files, recompute against the new denominator:

```
needed_hits = (TARGET_PCT/100 * (TOTAL_LINES + new_LF)) - COVERED_LINES
```

Budget with a **1.3x buffer**. Projection error on widget-heavy files routinely
runs 40%+ because early-return guards and error branches are easy to miss.

## 4. Yield model

Projected gain per file = `uncovered_lines x recoverability`, where
recoverability is set by archetype. These factors are calibrated on this
codebase, not generic:

| Archetype | Recoverability | Note |
| :--- | :--- | :--- |
| `domain/usecases/*` | 0.95 | Single call + `Either` fold. Nearly all lines reachable. |
| `domain/entities/*` | 0.90 | `copyWith`, `props`, computed getters. No setup. |
| `data/models/*` | 0.85 | `fromJson`/`toJson`; null branches need explicit cases. |
| `data/repositories/*_impl` | 0.80 | Needs mocked datasources; failure mappings are numerous but mechanical. |
| `data/datasources/*_impl` | 0.70 | Hive/Supabase surface; some paths need channel stubs. |
| `presentation/bloc/*` | 0.75 | `bloc_test` covers handlers well; some guards are hard to trigger. |
| `presentation/pages/*` | 0.55 | Build methods are long; dialogs, sheets, and nav callbacks resist. |
| `presentation/widgets/*` | 0.60 | Better than pages — smaller build methods. |
| `core/services/*` | 0.70 | Varies; platform-channel services are the low end. |
| `*.g.dart`, `l10n/*` | — | **Do not target.** Vanity coverage. |
| `main.dart`, `di/service_locator.dart` | 0.30 | Bootstrap wiring; expensive per line. |

Rank by `uncovered x recoverability`, tie-break on risk (money math, sync,
auth) and on branch density.

## 5. Where the lines are

Regenerate with the per-file command in §1. The stable structural picture:

- `lib/features/*/presentation/pages/**` holds the largest single pool of
  uncovered lines, at the *lowest* recoverability. Take these in bulk only after
  cheaper pools are exhausted, and prefer state-driven render assertions
  (loading / loaded / empty / error) which sweep large build methods quickly.
- `lib/features/*/data/repositories/**` is the best ratio in the repo: dense,
  branch-heavy, and fully mockable.
- `lib/core/sync/**` and `lib/core/auth/**` are marked **Restricted** in
  `AGENTS.md`. Tests against them are welcome; production edits need human
  review. Plan accordingly — do not start a defect fix there without flagging it.
- Flow tests in `test/integration/` are unusually efficient here: one flow test
  sweeps a page, its bloc, and its repository in a single pass. When a feature
  needs coverage across all three layers, the flow test is cheaper than three
  unit files.

## 6. Local vs CI thresholds

| Check | Threshold | Enforced by |
| :--- | :--- | :--- |
| Diff coverage (changed lines) | 80% | `ci/check_coverage.sh` via `diff-cover` |
| Total project coverage | 35% floor | `ci/check_coverage.sh` (warn locally, fail in CI) |

The 35% floor is a historical guard, not the goal. `diff-cover` requires
`pip install diff-cover` and an `origin/main` to compare against; without it the
script exits early, so on a detached or offline checkout use the awk one-liner
directly.

## 7. Traps

- **Coverage without `--coverage` deletes nothing but updates nothing either.**
  `coverage/lcov.info` is stale until you re-run. Always regenerate before
  quoting a number.
- **Partial runs produce partial lcov.** `flutter test path/to/one_test.dart
  --coverage` overwrites `lcov.info` with only that file's reach. Never compare a
  scoped run against a full-suite baseline.
- **Concurrency affects nothing but wall time** — but very high `--concurrency`
  on Windows can cause flaky timeouts in widget tests. 8 is the safe setting here.
- **`~` in the test output is skipped tests, not passes.** A rising skip count is
  a regression even when the run is green.
