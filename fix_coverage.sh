#!/bin/bash
git show HEAD | diff-cover --fail-under=80 /dev/stdin --compare-branch=origin/main
