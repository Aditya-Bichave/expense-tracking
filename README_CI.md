# CI/CD Quality Gates

This project uses a strict CI pipeline to ensure quality, performance, and stability.

## Pipeline Overview

The GitHub Actions workflow (`flutter-ci.yml`) runs the following checks:

1.  **Static Checks & Policy**:
    -   `dart format`
    -   `flutter analyze`
    -   **No Print/TODO**: Fails if `print()`, `debugPrint()`, or `TODO` (without ticket ID) are found in changed lines.
    -   **Codegen Consistency**: Checks if generated files (`.g.dart`) are up-to-date with source changes.

2.  **Unit Tests & Coverage**:
    -   Runs `flutter test` (including golden tests).
    -   **Diff Coverage**: Enforces 80% coverage on new/changed lines.
    -   **Total Coverage**: Enforces 35% overall coverage.

3.  **Web Build & Bundle Size**:
    -   Builds for Web (`flutter build web --release`).
    -   **Bundle Budget**: Enforces size limits defined in `ci/budgets.json`.

4.  **Web Smoke Tests**:
    -   Deploys the web build locally.
    -   Runs Playwright smoke tests (startup time, route checks, console errors).
    -   **Startup Time**: Fails if startup takes longer than 3000ms.

## Local Development

### Running Smoke Tests Locally

1.  Build the web app:
    ```bash
    flutter build web --release
    ```
2.  Navigate to `ci/smoke`:
    ```bash
    cd ci/smoke
    npm install
    npx playwright install chromium
    ```
3.  Run the smoke test:
    ```bash
    npm run smoke
    ```

### Updating Golden Tests

If you make UI changes that affect golden tests:

```bash
flutter test --update-goldens test/golden
```

**Note**: Golden files generated on different OSs (macOS/Windows) might differ from CI (Linux). Ideally, verify on Linux (Docker).

### Policy Checks

You can run policy checks locally against `main`:

```bash
./ci/policy/check_new_code.sh main
./ci/policy/check_codegen.sh main
```
