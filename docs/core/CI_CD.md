# CI/CD Pipeline

The project uses GitHub Actions for Continuous Integration and Deployment.
Pipeline: `.github/workflows/flutter-ci.yml`.

## Overview
1.  **Triggers**:
    *   Push to `main`.
    *   Pull Request to `main`.
    *   Manual Dispatch (Optional).

2.  **Jobs**:
    *   **Static Checks**:
        *   `dart format --output=none --set-exit-if-changed .` (Fails if formatting is needed).
        *   `flutter analyze` (Fails on lints).
        *   Policy Checks: No `print()` statements, no `TODO` without ID.
    *   **Build & Test**:
        *   Build Runners (`build_runner build`).
        *   Unit Tests (`flutter test`).
        *   Widget Tests (`flutter test`).
        *   Code Coverage Check (Diff >= 80%, Total >= 35%).
    *   **Web Build**:
        *   `flutter build web --release`.
        *   Bundle Size Check (see `ci/budgets.json`).
    *   **Smoke Tests**:
        *   Deploys Web Build locally.
        *   Runs Playwright Smoke Tests (Node.js).

## Local Usage
To verify changes before pushing:

### 1. Formatting & Analysis
```bash
dart format .
flutter analyze
```

### 2. Testing
```bash
flutter test
```

### 3. Policy Checks
```bash
./ci/policy/check_new_code.sh main
```

### 4. Web Build & Smoke Test
```bash
flutter build web --release
cd ci/smoke
npm install
npm run smoke
```
