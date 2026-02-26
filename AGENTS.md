# Expense Tracking AI Directives

**STATUS: ACTIVE**
**AUTHORITY: ROOT**

This file is the single source of truth for AI agents (Jules, etc.) modifying this repository.
Deviations from these rules must be explicitly approved by a human maintainer.

## 1. Hierarchy of Truth
1.  **User Instructions** (Explicit overrides in prompt)
2.  **`AGENTS.md`** (This file)
3.  **CI/CD Configuration** (`.github/workflows/`, `setup.sh`)
4.  **Core Documentation** (`docs/core/`)
5.  **Governance Policies** (`docs/governance/`)
6.  **Code Comments** (Inline documentation)

*Conflict Resolution:* If docs contradict CI/CD, trust CI/CD (execution is truth). If user contradicts docs, trust user (context is king).

## 2. Quickstart & Verification
Run these commands to verify the environment before starting work.

| Action | Command | Scope |
| :--- | :--- | :--- |
| **Install** | `./setup.sh` | System & Flutter deps |
| **Get Deps** | `flutter pub get` | Dart packages |
| **Codegen** | `flutter pub run build_runner build --delete-conflicting-outputs` | Hive, JSON, etc. |
| **Format** | `dart format .` | **MANDATORY** before commit |
| **Lint** | `flutter analyze` | **MANDATORY** before commit |
| **Test** | `flutter test` | **MANDATORY** before commit |
| **Web Build**| `flutter build web --release` | Verification for Web |

## 3. Safe Modification Protocol
1.  **Explore**: Read `docs/core/ARCHITECTURE.md` and related files in `docs/core/`.
2.  **Plan**: Use `set_plan` to outline steps.
    *   **CRITICAL**: Include a pre-commit step to run format, analyze, and test.
3.  **Verify**:
    *   After *every* file change, verify syntax/logic.
    *   Run `flutter analyze` frequently.
    *   Run relevant tests (`flutter test path/to/test.dart`).
4.  **Reflect**:
    *   Did you break the build?
    *   Did you introduce a `print` statement? (Forbidden!)
    *   Did you leave a `TODO` without an issue ID? (Forbidden!)

## 4. Automation Boundaries
*See [docs/governance/AUTOMATION_BOUNDARIES.md](docs/governance/AUTOMATION_BOUNDARIES.md) for full details.*

| Component | AI Access Level | Note |
| :--- | :--- | :--- |
| `lib/features/*` | **High** | Safe to modify business logic with tests. |
| `lib/core/auth` | **Restricted** | **Review Required**. Security critical. |
| `lib/core/sync` | **Restricted** | **Review Required**. Data integrity critical. |
| `.github/workflows`| **Read-Only** | Do not modify CI unless explicitly asked. |
| `setup.sh` | **Read-Only** | Environment is immutable. |

## 5. Key Pitfalls
*   **Hive Keys**: Do not change Hive TypeIds or FieldIds without migration strategy.
*   **Supabase Sync**: Always use `Outbox` pattern for offline support. Do not call Supabase directly in UI.
*   **State Management**: Use Bloc events/states. Do not use `setState` for business logic.
*   **Formatting**: The CI pipeline will fail if code is not formatted with `dart format .`.

## 6. Documentation Index
*   [Architecture & Sync](docs/core/ARCHITECTURE.md)
*   [Testing Strategy](docs/core/TESTING.md)
*   [Coding Standards](docs/core/CODING_STANDARDS.md)
*   [CI/CD Pipeline](docs/core/CI_CD.md)
*   [Deployment Guide](docs/core/DEPLOYMENT.md)
*   [Security Model](docs/core/SECURITY_MODEL.md)
*   [Governance & Risks](docs/governance/)
