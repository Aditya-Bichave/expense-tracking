#!/bin/bash
flutter test --coverage --test-randomize-ordering-seed=random --concurrency 16
awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{ pct=(lf?100*lh/lf:0); printf("Coverage: %.2f%%\n", pct); }' coverage/lcov.info
