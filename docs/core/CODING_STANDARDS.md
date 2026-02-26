# Coding Standards

This project adheres to strict coding standards to maintain readability, reliability, and CI compliance.

## 1. General Principles
*   **Language**: Dart 3 (null-safety, patterns, records).
*   **Style**: Official Flutter/Dart style guide.
*   **Tooling**: Use `dart format` and `flutter analyze` religiously.

## 2. Formatting (MANDATORY)
The CI pipeline will **reject** any PR that is not formatted with `dart format .`.
*   Run `dart format .` before every commit.

## 3. Linting (MANDATORY)
The CI pipeline enforces `flutter_lints` and custom analysis rules.
*   **Forbidden**:
    *   `print()` (Use `debugPrint` or a logger, but remove before merge).
    *   `TODO` without a ticket ID (e.g., `// TODO(#123): Fix this`).
    *   Unused imports/variables.
    *   Explicit `dynamic` types where specific types exist.

## 4. Architecture Rules
*   **State Management**: Use `flutter_bloc`. Never modify business state inside `build()`.
*   **Dependency Injection**: Use `GetIt`. Never instantiate repositories directly in UI.
*   **Async/Await**: Prefer `async`/`await` over `.then()`.

## 5. Naming Conventions
*   **Files**: `snake_case.dart`
*   **Classes**: `PascalCase`
*   **Variables/Methods**: `camelCase`
*   **Constants**: `SCREAMING_SNAKE_CASE` or `kCamelCase` (if private/internal).

## 6. Comments
*   **Public API**: Document public classes and methods with `///` comments.
*   **Complexity**: Explain *why*, not *what*, for complex logic.
