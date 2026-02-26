# Risk Register

## Structural Risks
The following areas of the codebase are known to be complex, fragile, or carry high risk.

| Risk ID | Component | Description | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **R-01** | `lib/core/sync/` | Sync logic is complex and prone to race conditions between Hive (local) and Supabase (remote). | Use `Outbox` pattern religiously. Rely on Supabase Realtime for updates. |
| **R-02** | `Hive` Schema | Changing `HiveType` or `HiveField` IDs breaks backward compatibility and causes data loss on user devices. | **NEVER** change existing IDs. Add new fields as nullable. Use migrations if necessary. |
| **R-03** | `Supabase` Auth | Reliance on external auth provider (Supabase) creates a single point of failure. | Ensure local-first functionality works even if auth is unavailable (read-only mode if cached). |
| **R-04** | `CI/CD` Pipeline | Strict linting rules (no `print`, etc.) can block urgent fixes if not followed. | Use `debugPrint` during dev, remove before commit. Run `dart format .` locally. |
| **R-05** | `Golden Tests` | Golden files generated on different OSs (macOS vs Linux) may differ slightly due to font rendering. | Update goldens on Linux (Docker) or tolerate minor diffs. |

## Technical Debt
| Debt ID | Component | Description | Plan |
| :--- | :--- | :--- | :--- |
| **D-01** | `analysis_options.yaml` | Many `ignore` rules are currently enabled, masking potential issues. | Gradually enable stricter rules and fix warnings. |
| **D-02** | `test/golden/` | Golden tests are flaky on different platforms. | Standardize test environment (Docker). |
