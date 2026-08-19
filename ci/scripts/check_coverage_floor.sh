#!/usr/bin/env bash
#
# Ratcheting total-coverage gate.
#
# The floor lives in ci/coverage-floor.txt, in version control, so lowering it is
# a reviewable diff rather than an invisible drift. Coverage below the floor
# fails. Coverage comfortably above it prints an instruction to raise the floor,
# which is what makes this a ratchet instead of a fixed threshold that coverage
# can sag against forever.
#
# Usage: check_coverage_floor.sh [lcov-file] [floor-file]
set -euo pipefail

LCOV=${1:-coverage/lcov.info}
FLOOR_FILE=${2:-ci/coverage-floor.txt}

# How far above the floor coverage must climb before we ask for a bump. Small
# enough to keep the floor honest, large enough not to nag on noise.
RAISE_MARGIN=1.0

[[ -f "$LCOV" ]] || { echo "Coverage file not found: $LCOV" >&2; exit 1; }
[[ -f "$FLOOR_FILE" ]] || { echo "Floor file not found: $FLOOR_FILE" >&2; exit 1; }

FLOOR=$(tr -d '[:space:]' < "$FLOOR_FILE")

PCT=$(awk -F: '
  /^LF:/{lf+=$2} /^LH:/{lh+=$2}
  END{ printf("%.2f", (lf ? 100*lh/lf : 0)) }
' "$LCOV")

echo "Total coverage: ${PCT}%  (floor ${FLOOR}%)"

awk -v pct="$PCT" -v floor="$FLOOR" -v margin="$RAISE_MARGIN" '
  BEGIN {
    if (pct + 0 < floor + 0) {
      printf("::error::Total coverage %.2f%% is below the floor of %s%%.\n", pct, floor)
      exit 1
    }
    if (pct + 0 >= floor + margin) {
      printf("::warning::Total coverage %.2f%% now exceeds the floor of %s%% by more than %.1f points. Raise ci/coverage-floor.txt to %.2f to lock the gain in.\n", pct, floor, margin, pct)
    }
    printf("Coverage gate passed.\n")
  }
'
