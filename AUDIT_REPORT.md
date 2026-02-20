# Sprint Guru — Technical Debt Dashboard & Ticket Report

## 📊 Technical Debt Dashboard

| Metric | Score | Status | Trend |
| :--- | :---: | :---: | :---: |
| **Overall Health** | **78/100** | 🟡 Good | Stable |
| Architecture | 85/100 | 🟢 Strong | Clean Architecture + BLoC is solid. |
| Security | 60/100 | 🔴 Critical | Non-blocking App Lock is a major vulnerability. |
| Performance | 70/100 | 🟡 Moderate | Startup latency risks due to eager Bloc loading. |
| Testing Maturity | 80/100 | 🟢 Good | 860+ tests, but sparse Integration/E2E coverage. |
| Code Quality | 65/100 | 🟡 Moderate | Linting rules are too permissive; hiding potential bugs. |

### 🚨 Top 3 Systemic Risks
1.  **Security Bypass:** The Biometric App Lock can be bypassed by dismissing the dialog or cancelling authentication.
2.  **Silent Failures:** `SupabaseClientProvider` catches initialization errors and proceeds with dummy values, masking configuration issues in production.
3.  **Data Integrity:** The custom Sync mechanism (`SyncService`) lacks conflict resolution strategies and permanently fails after 5 retries, risking data loss in offline scenarios.

---

## 🚀 Epics & Tickets

### EPIC-1: Security Hardening & Compliance
*Refining authentication flows, securing local data, and enforcing access controls.*

**1. [Security] Fix App Lock Bypass Vulnerability**
*   **Priority:** P0
*   **Effort:** S
*   **Problem:** The `_checkLock` method in `main.dart` calls `localAuth.authenticate` but does not block the UI or exit the app if authentication fails or is cancelled.
*   **Root Cause:** Error handling in `_checkLock` only logs the error; it does not enforce a lockout state.
*   **Suggested Direction:** Wrap the entire app in a `LockScreen` widget that conditionally renders the `MaterialApp` or a blockage screen based on `SettingsBloc` state. Ensure the `authenticate` call is a blocking loop or overlays a non-dismissible route.
*   **Files:** `lib/main.dart`

**2. [Security] Enforce Strict Initialization for Supabase**
*   **Priority:** P1
*   **Effort:** XS
*   **Problem:** `SupabaseClientProvider` catches errors during init and uses placeholder values. This can lead to silent failures where the app "works" but doesn't sync.
*   **Suggested Direction:** In production builds, initialization failure should be fatal or trigger a distinct "Maintenance Mode" UI. Remove the "placeholder" fallback for release builds.
*   **Files:** `lib/core/network/supabase_client_provider.dart`

**3. [Security] Audit & Verify RLS Policies for Profiles**
*   **Priority:** P1
*   **Effort:** S
*   **Problem:** While `expenses.sql` and `groups.sql` have policies, `profiles.sql` needs verification to ensure users cannot enumerate other users' metadata (email/phone) via `profiles` table.
*   **Suggested Direction:** Verify `supabase/rls/profiles.sql` restricts `SELECT` to `auth.uid() = user_id` or specific shared groups.
*   **Files:** `supabase/rls/profiles.sql`

---

### EPIC-2: Architecture Modernization & Code Quality
*Improving maintainability, type safety, and developer tooling.*

**4. [Architecture] Enforce Pedantic Lint Rules**
*   **Priority:** P1
*   **Effort:** M
*   **Problem:** `analysis_options.yaml` ignores critical rules like `use_build_context_synchronously` and `prefer_const_constructors`.
*   **Suggested Direction:** Adopt `package:flutter_lints/flutter.yaml` defaults or stricter rules (e.g., `very_good_analysis`). Fix the resulting cascade of warnings (likely 100+).
*   **Files:** `analysis_options.yaml`

**5. [Architecture] Refactor Manual Hive Adapter Registration**
*   **Priority:** P2
*   **Effort:** S
*   **Problem:** `main.dart` contains a long list of `Hive.registerAdapter` calls. This is prone to merge conflicts and forgetting to register new adapters.
*   **Suggested Direction:** Create a `HiveRegistrar` class or use code generation to auto-register all adapters in a single module.
*   **Files:** `lib/main.dart`

**6. [Architecture] Replace Fragile Route Arguments**
*   **Priority:** P2
*   **Effort:** M
*   **Problem:** `GoRouter` routes (e.g., `RouteNames.editTransaction`) accept complex objects via `state.extra`. This breaks if the app is killed/restored or deep-linked.
*   **Suggested Direction:** Pass only IDs in the route path. Fetch the entity from the Repository/Bloc using the ID in the destination page.
*   **Files:** `lib/router.dart`

**7. [Architecture] Standardize BlocObserver Error Handling**
*   **Priority:** P3
*   **Effort:** XS
*   **Problem:** The custom `BlocObserver` (if present, or default) might not be catching all uncaught exceptions from Blocs uniformly.
*   **Suggested Direction:** Ensure `SimpleBlocObserver` overrides `onError` correctly with the updated Bloc API signature (check `bloc` package version compatibility).
*   **Files:** `lib/core/utils/bloc_observer.dart`

---

### EPIC-3: Performance Optimization
*Reducing startup time and improving UI responsiveness.*

**8. [Performance] Optimize App Startup (Lazy Loading)**
*   **Priority:** P1
*   **Effort:** S
*   **Problem:** `MultiBlocProvider` in `main.dart` initializes 8+ Blocs with `lazy: false` (implied or explicit). This forces all data to load on splash screen.
*   **Suggested Direction:** Set `lazy: true` (default) for non-critical Blocs (e.g., `BudgetListBloc`, `GoalListBloc`). Only keep `SettingsBloc` and `AuthBloc` eager.
*   **Files:** `lib/main.dart`

**9. [Performance] Implement Asset Caching Strategy**
*   **Priority:** P2
*   **Effort:** M
*   **Problem:** High reliance on assets (SVGs/Images) without explicit pre-caching might cause jank on first render of heavy screens (Dashboard).
*   **Suggested Direction:** Use `precacheImage` for critical assets in `main.dart` or a splash screen loader.
*   **Files:** `lib/main.dart`, `assets/`

---

### EPIC-4: Data Sync & Reliability
*Ensuring data integrity in offline-first scenarios.*

**10. [Data] Implement Conflict Resolution Strategy**
*   **Priority:** P1
*   **Effort:** L
*   **Problem:** `SyncService` blindly pushes local changes. If the server state has changed, it might overwrite or fail without user recourse.
*   **Suggested Direction:** Implement a "Last Write Wins" or "Merge" strategy. If a sync fails due to conflict, prompt the user or auto-resolve based on timestamps.
*   **Files:** `lib/core/sync/sync_service.dart`

**11. [Data] Improve Sync Error Handling & Retry Logic**
*   **Priority:** P2
*   **Effort:** M
*   **Problem:** Items failing 5 times are marked as permanently failed. Users are not notified.
*   **Suggested Direction:** Expose a "Sync Status" stream. Show a UI indicator if items are in "Permanently Failed" state, allowing manual retry or deletion.
*   **Files:** `lib/core/sync/sync_service.dart`

**12. [Data] Encrypt Sensitive Hive Boxes**
*   **Priority:** P2
*   **Effort:** M
*   **Problem:** Hive boxes (Expenses, Accounts) are likely unencrypted on disk.
*   **Suggested Direction:** Use `Hive.openBox(..., encryptionCipher: HiveAesCipher(key))` using a key stored in `FlutterSecureStorage`.
*   **Files:** `lib/main.dart`

---

### EPIC-5: Testing & QA
*Increasing confidence in releases.*

**13. [Testing] Add Integration Tests for Core Flows**
*   **Priority:** P2
*   **Effort:** L
*   **Problem:** While unit test count is high, critical user flows (Login -> Dashboard -> Add Expense) lack end-to-end coverage.
*   **Suggested Direction:** Create `integration_test/app_test.dart` using `integration_test` package to simulate a full user session.
*   **Files:** `integration_test/`

**14. [Testing] Visual Regression Testing**
*   **Priority:** P3
*   **Effort:** M
*   **Problem:** UI changes might break layout without detection.
*   **Suggested Direction:** Implement Golden Tests for complex widgets (`DashboardPage`, `TransactionItem`).
*   **Files:** `test/features/dashboard/`

---

*Note: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*
