#!/usr/bin/env bash
#
# Installs apt packages on a GitHub-hosted runner, without hanging.
#
# GitHub's Ubuntu runners resolve mirrors through /etc/apt/apt-mirrors.txt, which
# lists azure.archive.ubuntu.com first. That host is frequently unreachable from
# the runner, and apt then retries with backoff before falling back to a slower
# https mirror. Observed cost: 15+ minutes, long enough to consume a job's entire
# timeout-minutes. The job then reports as "cancelled" with no indication of which
# step stalled, which is how this cost three separate jobs in this pipeline
# (Playwright deps, psql client, and very nearly lcov).
#
# So: point the mirrorlist at the canonical archive before updating, and bound
# every apt call with a retry loop instead of trusting a single attempt.
#
# Usage: apt_install.sh <package> [package...]
set -euo pipefail

[[ $# -gt 0 ]] || { echo "usage: $0 <package> [package...]" >&2; exit 2; }

export DEBIAN_FRONTEND=noninteractive

# Prefer the canonical archive. Guarded because the mirrorlist is a runner-image
# detail, not a documented interface -- if it is missing or already points
# elsewhere, apt's own configuration stands.
if [[ -f /etc/apt/apt-mirrors.txt ]]; then
  if grep -q 'azure.archive.ubuntu.com' /etc/apt/apt-mirrors.txt; then
    echo "Repointing apt mirrorlist away from azure.archive.ubuntu.com"
    sudo sed -i 's|http://azure.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|g' \
      /etc/apt/apt-mirrors.txt
  fi
fi

retry() {
  local attempts=$1; shift
  local n=1
  until "$@"; do
    if (( n >= attempts )); then
      echo "::error::'$*' failed after $n attempt(s)" >&2
      return 1
    fi
    echo "attempt $n of $attempts failed; retrying in $((n * 5))s: $*" >&2
    sleep $((n * 5))
    ((n++))
  done
}

# `-o Acquire::Retries=1` keeps apt from adding its own long internal retry loop
# on top of ours, which is what made the original stall so slow to surface.
retry 3 sudo apt-get update -o Acquire::Retries=1 -qq
retry 3 sudo apt-get install -y --no-install-recommends -o Acquire::Retries=1 -qq "$@"

echo "Installed: $*"
