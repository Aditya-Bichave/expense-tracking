#!/bin/bash
git fetch origin main
diff-cover coverage/lcov.info --compare-branch=origin/main
