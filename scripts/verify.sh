#!/usr/bin/env bash
#
# Local pre-push verification. Runs the same gates as
# .github/workflows/flutter-ci.yml, in the same order, so a green run here means
# a green `static-checks` and `unit-tests` in CI.
#
# Usage:
#   ./scripts/verify.sh              # format + analyze + tests + coverage
#   ./scripts/verify.sh --no-coverage  # skip the slower coverage gates
#
# Not covered here: the web build, bundle-size, smoke and E2E jobs. For those see
# ./run_e2e.sh and ci/smoke/.
set -euo pipefail

WITH_COVERAGE=1
[[ "${1:-}" == "--no-coverage" ]] && WITH_COVERAGE=0

# Thresholds must match flutter-ci.yml. If you change one, change it there too.
TOTAL_COVERAGE_FLOOR=75
DIFF_COVERAGE_FLOOR=80

step() { printf '\n=== %s ===\n' "$1"; }

step 'Dependencies'
flutter pub get

# Must run after `pub get`: `dart format` reads the language version from
# .dart_tool/package_config.json, and without it reformats the whole repo.
step 'Format check'
dart format . --output=none --set-exit-if-changed

step 'Static analysis'
flutter analyze

step 'Lockfile policy'
./ci/policy/check_lockfile.sh

if [[ $WITH_COVERAGE -eq 0 ]]; then
  step 'Tests (no coverage)'
  flutter test --test-randomize-ordering-seed=random --concurrency 4
  echo -e '\nAll checks passed.'
  exit 0
fi

step 'Tests with coverage'
flutter test --coverage --test-randomize-ordering-seed=random --concurrency 4

step "Total coverage (>= ${TOTAL_COVERAGE_FLOOR}%)"
awk -F: -v floor="$TOTAL_COVERAGE_FLOOR" '
  /^LF:/{lf+=$2} /^LH:/{lh+=$2}
  END{
    pct=(lf?100*lh/lf:0)
    printf("Coverage: %.2f%%\n", pct)
    if (pct < floor) { printf("Below %d%%\n", floor); exit 1 }
  }' coverage/lcov.info

step "Diff coverage (>= ${DIFF_COVERAGE_FLOOR}%)"
if command -v diff-cover >/dev/null 2>&1; then
  git fetch origin main || true
  diff-cover coverage/lcov.info --compare-branch=origin/main \
    --fail-under="$DIFF_COVERAGE_FLOOR"
else
  echo 'diff-cover not installed; skipping (pip install diff-cover)'
fi

echo -e '\nAll checks passed.'
