#!/bin/bash
git checkout -b temp2
git add .
git commit -m "temp2"
flutter test --coverage
pip install diff-cover
diff-cover coverage/lcov.info --compare-branch=main
