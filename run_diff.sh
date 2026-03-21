#!/bin/bash
git checkout -b temp
git add .
git commit -m "temp"
flutter test --coverage
pip install diff-cover
diff-cover coverage/lcov.info --compare-branch=main
