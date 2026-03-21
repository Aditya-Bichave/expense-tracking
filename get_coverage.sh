#!/bin/bash
awk -F: '/^SF:/{file=$2} /^LF:/{lf=$2} /^LH:/{lh=$2; pct=(lf?100*lh/lf:0); if (pct < 80) printf("%s: %.2f%%\n", file, pct)}' coverage/lcov.info
