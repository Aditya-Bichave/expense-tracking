# Testing Strategy

This project uses a layered testing approach to ensure reliability and performance.

## 1. Unit Tests (`test/`)
*   **Purpose**: Verify business logic (Blocs, UseCases, Repositories).
*   **Coverage**: High (~80% mandated by CI).
*   **Framework**: `flutter_test`, `bloc_test`, `mocktail`.
*   **Command**: `flutter test`

### Best Practices
*   Use `mocktail` for dependencies.
*   Test for both success and failure states.
*   Verify side effects (e.g., logging, navigation).

## 2. Widget Tests (`test/widgets/`)
*   **Purpose**: Verify UI rendering and user interactions.
*   **Coverage**: Critical paths (Login, Transaction Creation, Dashboard).
*   **Framework**: `flutter_test`.
*   **Command**: `flutter test`

### Best Practices
*   Use `tester.pump()` for simple updates, `tester.pumpAndSettle()` for animations.
*   Mock providers using `MockProvider` or `BlocProvider.value`.
*   Verify `Key`s exist for specific UI elements.

## 3. Golden Tests (`test/golden/`)
*   **Purpose**: Visual regression testing. Ensures UI looks consistent across devices/commits.
*   **Update Command**: `flutter test --update-goldens test/golden`
*   **Platform**: Golden files should ideally be generated in a Linux/Docker environment (CI baseline) to avoid font rendering discrepancies.

## 4. Web Smoke Tests (`ci/smoke/`)
*   **Purpose**: End-to-end verification of the web build.
*   **Framework**: Playwright (Node.js).
*   **Tests**: Startup time, basic navigation, console errors.
*   **Run Command**:
    ```bash
    flutter build web --release
    cd ci/smoke && npm install && npm run smoke
    ```

## 5. CI Pipeline (`.github/workflows/flutter-ci.yml`)
The CI pipeline automatically runs all tests on every push/PR to `main`.
*   Fails if coverage drops below threshold.
*   Fails if formatting or analysis errors are present.
*   Fails if `TODO`s exist without ticket IDs.
