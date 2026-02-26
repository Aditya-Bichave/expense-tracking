# Decision Priority Matrix

This matrix defines the prioritization of potentially conflicting goals in the project.

## 1. Core Principles

| Priority | Principle | Rationale |
| :--- | :--- | :--- |
| **P0** | **Data Integrity** | Financial data must be correct. Losing user data is unacceptable. |
| **P1** | **Security** | Access to financial data must be strictly controlled (Auth + RLS). |
| **P2** | **Stability** | Crashes and hangs are unacceptable. Offline-first ensures uptime. |
| **P3** | **Performance** | UI must be responsive (Hive reads), but accuracy > speed. |
| **P4** | **Maintainability**| Code must be readable and testable for long-term health. |

## 2. Trade-offs

| If conflict arises between... | Choose... | Why? |
| :--- | :--- | :--- |
| **Correctness vs. Performance** | **Correctness** | Incorrect financial data is a bug, even if fast. |
| **Security vs. Convenience** | **Security** | We hold user financial data. Better safe than sorry. |
| **Testability vs. Code Size** | **Testability** | Extra interfaces/wrappers are acceptable if they enable testing. |
| **New Features vs. Stability** | **Stability** | Don't ship broken features. Fix existing bugs first. |
| **Strict Linting vs. Speed** | **Strict Linting**| `dart format .` and `flutter analyze` are mandatory, even if annoying. |

## 3. Implementation Guidelines
*   **Use `Hive` for Reads**: Prioritize UI responsiveness.
*   **Use `Supabase` for Source of Truth**: Backend data is definitive, local is cache.
*   **Use `Bloc` for Logic**: Keep business logic separate from UI.
