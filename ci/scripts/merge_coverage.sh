#!/usr/bin/env bash
#
# Merges the per-shard lcov files produced by the sharded test matrix into a
# single coverage/lcov.info.
#
# Concatenating lcov files is NOT equivalent: shards run different test files but
# cover overlapping library files, so a plain `cat` emits duplicate records for
# the same source file and double-counts its lines. `lcov -a` sums hit counts per
# line and unions the line sets, which is what a coverage percentage needs.
#
# Usage: merge_coverage.sh <shard-dir> <output-file>
set -euo pipefail

SHARD_DIR=${1:?shard directory required}
OUTPUT=${2:-coverage/lcov.info}

mapfile -t files < <(find "$SHARD_DIR" -name 'lcov*.info' -size +0 | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No non-empty lcov files found under $SHARD_DIR" >&2
  exit 1
fi

echo "Merging ${#files[@]} shard coverage file(s):"
printf '  %s\n' "${files[@]}"

mkdir -p "$(dirname "$OUTPUT")"

args=()
for f in "${files[@]}"; do
  args+=(-a "$f")
done

# --ignore-errors so one shard that recorded an empty/odd record cannot fail the
# whole merge; the remaining shards still contribute their counts.
lcov "${args[@]}" -o "$OUTPUT" --ignore-errors empty,inconsistent 2>&1 | tail -5

echo "Merged coverage written to $OUTPUT"
