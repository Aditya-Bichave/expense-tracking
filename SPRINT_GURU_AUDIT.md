# Sprint Guru Audit Report

**Date:** 2026-02-22
**Auditor:** Sprint Guru AI (Jules)
**Project:** Spend Savvy (Flutter + Supabase)

---

## Phase 1: Full Project Analysis

### 1. Architecture & Code Quality
- **Strengths:** The project follows a robust **Clean Architecture** combined with **Feature-first** packaging. The separation of concerns (Data, Domain, Presentation) is evident in modules like `goals`, `accounts`, and `expenses`. Dependency Injection via `GetIt` is correctly implemented.
- **Weaknesses:**
    - **God Class:** `lib/main.dart` is overloaded with initialization logic (Hive, Logger, Supabase, Migrations), violating the Single Responsibility Principle.
    - **Eager Loading:** `MultiBlocProvider` in `main.dart` initializes all major Blocs at startup (`lazy: false`), which will degrade launch performance as the app scales.
    - **Hardcoding:** Critical logic in `SyncService` relies on hardcoded table name strings, prone to typos and maintenance headaches.

### 2. Security
- **CRITICAL VULNERABILITY:** The Biometric Authentication implementation in `_MyAppState` (`lib/main.dart`) ignores the result of `_localAuth.authenticate`. A user can simply dismiss the prompt or fail auth and still access the app. **(Severity: P0)**.
- **Data Privacy:** Local Hive boxes (storing financial data) do not appear to use encryption keys by default in the initialization logic seen in `main.dart`.
- **RLS Policies:** The `expenses` table in Supabase (mapped to `GroupExpenseModel`) has RLS policies checking `group_members`, which is correct for group expenses but the generic name `expenses` causes confusion with local-only personal expenses.

### 3. Performance
- **Startup Latency:** The sequential awaiting of Hive box opening (though initiated in parallel) combined with eager Bloc creation creates a heavy startup phase.
- **List Rendering:** Transaction lists load all data at once; pagination is missing, posing a risk for users with thousands of records.

### 4. Testing & DevOps
- **Testing:** Unit test coverage is decent for core logic (`goals`, `accounts`), but integration tests for the critical `SyncService` are missing. Logs show significant "noise" from mocked exceptions, indicating tests might be brittle or logging is too verbose during test runs.
- **CI/CD:** Basic analysis and testing are present, but linting rules seem lenient (no `unawaited_futures` warning caught the auth bypass).

---

## Phase 4: Technical Debt Dashboard

| Metric | Score (0-100) | Status | Notes |
| :--- | :---: | :--- | :--- |
| **Overall Project Health** | **72** | 🟡 | Solid architecture dragged down by critical security flaw. |
| **Security Risk** | **30** | 🔴 | **CRITICAL:** Biometric Auth Bypass active. |
| **Architecture Consistency** | **85** | 🟢 | Clean Architecture well implemented. |
| **Performance Risk** | **65** | 🟡 | Eager loading & lack of pagination are ticking time bombs. |
| **Testing Maturity** | **75** | 🟢 | Good unit coverage; Integration/E2E needed. |
| **Maintainability** | **70** | 🟡 | `main.dart` refactor needed; hardcoded strings in Sync. |

### Top 5 Systemic Risks
1.  **Biometric Auth Bypass** (Security)
2.  **App Startup Bottleneck** (Performance)
3.  **Sync Service Fragility** (Data Integrity)
4.  **Unencrypted Local Data** (Privacy)
5.  **Unlimited List Rendering** (Scalability)

### Suggested Sprint Focus
**Immediate Priority:** Fix the Biometric Bypass (P0).
**Secondary:** Refactor `main.dart` and `MultiBlocProvider` to improve startup time and maintainability.
**Tertiary:** Harden `SyncService` with better error handling and integration tests.

---

## Phase 2 & 3: Ticket List

### Epic 1: Security Hardening & Data Privacy

#### 1. [Security] Fix Biometric Auth Bypass in `main.dart`
- **Priority:** P0 (Critical)
- **Effort:** XS
- **Module:** App Core (`lib/main.dart`)
- **Problem:** `_checkLock` method calls `localAuth.authenticate` but ignores the boolean return value.
- **Root Cause:** Missing `await` check or boolean validation.
- **Suggested Direction:**
  ```dart
  final didAuthenticate = await _localAuth.authenticate(...);
  if (!didAuthenticate) { /* Exit app or show lock screen overlay */ }
  ```
- **Acceptance Criteria:** App MUST NOT reveal content until `authenticate` returns `true`.

#### 2. [Security] Encrypt Local Hive Boxes
- **Priority:** P2
- **Effort:** M
- **Module:** Core Data
- **Problem:** Financial data is stored in plain text in Hive boxes.
- **Root Cause:** `Hive.openBox` called without `encryptionCipher`.
- **Suggested Direction:** Use `flutter_secure_storage` to generate/store a key, then use `HiveAesCipher` when opening boxes.

#### 3. [Security] Audit RLS Policies for `group_members`
- **Priority:** P1
- **Effort:** S
- **Module:** Backend (Supabase)
- **Problem:** Ensure `expenses` (Group Expenses) policies strictly enforce `role` checks (admin/member) for writes.
- **Suggested Direction:** Review `supabase/rls/expenses.sql` and add test cases in `test/rules` (if Supabase local dev setup exists) or manual verification.

#### 4. [DevOps] Enable `unawaited_futures` Lint Rule
- **Priority:** P2
- **Effort:** XS
- **Module:** DevOps
- **Problem:** The Biometric bypass was caused by an ignored Future result.
- **Suggested Direction:** Add `unawaited_futures: error` to `analysis_options.yaml`.

---

### Epic 2: Architectural Refactor & Performance

#### 5. [Architecture] Refactor `main.dart` into `AppBootstrap`
- **Priority:** P1
- **Effort:** M
- **Module:** Core
- **Problem:** `main.dart` contains 200+ lines of initialization logic.
- **Suggested Direction:** Create `lib/core/app_bootstrap.dart`. Move Hive, Logger, Supabase init logic there. `main.dart` should only call `Bootstrap.init()` and `runApp`.

#### 6. [Performance] Implement Lazy Loading for Blocs
- **Priority:** P1
- **Effort:** S
- **Module:** App Core (`MultiBlocProvider`)
- **Problem:** All Blocs (`AccountList`, `TransactionList`, etc.) are created at startup.
- **Suggested Direction:** Remove `lazy: false` from `BlocProvider`s in `main.dart` unless absolutely necessary (e.g., `AuthBloc`). Let them initialize when their UI is built.

#### 7. [Architecture] Centralize Supabase Table Names
- **Priority:** P2
- **Effort:** S
- **Module:** Core Sync
- **Problem:** `SyncService` uses hardcoded strings like `'expenses'`, `'groups'`.
- **Suggested Direction:** Create `SupabaseTables` constant class or Enum extension.
  ```dart
  class SupabaseTables {
    static const groupExpenses = 'expenses';
    // ...
  }
  ```

#### 8. [Tech Debt] Rename `expenses` table to `group_expenses`
- **Priority:** P2
- **Effort:** L (Migration required)
- **Module:** Backend / Data
- **Problem:** The table name `expenses` is ambiguous (implies personal expenses).
- **Suggested Direction:** Rename table in Supabase. Update `GroupExpenseModel` and `SyncService`. **Requires DB Migration script.**

#### 9. [Performance] Transaction List Pagination
- **Priority:** P3
- **Effort:** M
- **Module:** Feature (Transactions)
- **Problem:** `TransactionListBloc` loads all transactions. O(N) memory usage.
- **Suggested Direction:** Implement `limit` and `offset` in `TransactionRepository`. Update UI to support infinite scroll.

#### 10. [Architecture] Abstract Hive Opening
- **Priority:** P3
- **Effort:** S
- **Module:** Core Data
- **Problem:** `main.dart` manually opens 14 boxes.
- **Suggested Direction:** Create `StorageService` or `HiveDatabase` class that iterates over a configuration of boxes to open them (possibly in parallel batches).

---

### Epic 3: Sync & Data Integrity

#### 11. [Feature] "Force Sync" Button
- **Priority:** P2
- **Effort:** S
- **Module:** Settings / Sync
- **Problem:** Users cannot manually trigger a sync if the auto-sync fails or is delayed.
- **Suggested Direction:** Add button in Settings -> Data Management that calls `SyncService.processOutbox()`.

#### 12. [Testing] Integration Tests for `SyncService`
- **Priority:** P2
- **Effort:** M
- **Module:** Core Sync
- **Problem:** Critical sync logic has no integration tests covering the retry/backoff mechanism.
- **Suggested Direction:** Create a test using `mockito` for SupabaseClient and verify `processOutbox` retries and error handling.

#### 13. [Feature] "Retry" for Failed Outbox Items
- **Priority:** P3
- **Effort:** M
- **Module:** Settings / Sync
- **Problem:** Failed items (after max retries) are stuck.
- **Suggested Direction:** UI to view `outbox` items with status `failed`. Button to reset `retryCount` and `nextRetryAt`.

#### 14. [Tech Debt] Remove Hardcoded `_maxRetries`
- **Priority:** P3
- **Effort:** XS
- **Module:** Core Sync
- **Problem:** `_maxRetries = 5` is hardcoded in `SyncService`.
- **Suggested Direction:** Move to `AppConfig` or `RemoteConfig`.

---

### Epic 4: UX & Features

#### 15. [UX] Biometric Lock Timeout
- **Priority:** P2
- **Effort:** S
- **Module:** App Core
- **Problem:** App locks immediately upon backgrounding. Annoying for switching apps briefly (e.g., to copy OTP).
- **Suggested Direction:** Add a grace period (e.g., 30 seconds) before requiring auth again.

#### 16. [Feature] Export Data to CSV
- **Priority:** P3
- **Effort:** M
- **Module:** Settings
- **Problem:** Users want to analyze data in Excel.
- **Suggested Direction:** Use `csv` package. specific UseCase `ExportTransactionsUseCase`.

#### 17. [UX] Skeleton Loading for Dashboard
- **Priority:** P3
- **Effort:** S
- **Module:** Dashboard
- **Problem:** Circular spinners provide poor perceived performance.
- **Suggested Direction:** Use `shimmer` package to show placeholder blocks for charts/lists.

#### 18. [UX] "Offline Mode" Indicator
- **Priority:** P3
- **Effort:** S
- **Module:** UI Shell
- **Problem:** Users don't know if they are offline (sync won't work).
- **Suggested Direction:** Listen to `ConnectivityPlus`. Show small banner or icon if offline.

#### 19. [Feature] Budget Alerts
- **Priority:** P3
- **Effort:** M
- **Module:** Budgets
- **Problem:** Users want to know when they hit 80%, 100% of budget.
- **Suggested Direction:** Local Notifications using `flutter_local_notifications`. Check budget status on expense addition.

#### 20. [UX] Haptic Feedback
- **Priority:** P3
- **Effort:** XS
- **Module:** UI
- **Problem:** App feels "flat".
- **Suggested Direction:** Add `HapticFeedback.lightImpact()` on button taps and successful saves.

---

### Epic 5: Maintenance & Tech Debt

#### 21. [Tech Debt] Extract `_initFileLogger`
- **Priority:** P3
- **Effort:** XS
- **Module:** Core Utils
- **Problem:** Private method in `main.dart`.
- **Suggested Direction:** Move to `LoggerService` or similar.

#### 22. [Tech Debt] Standardize Error Handling
- **Priority:** P3
- **Effort:** M
- **Module:** Core
- **Problem:** Inconsistent use of `Failure` classes vs Exceptions.
- **Suggested Direction:** Enforce `Either<Failure, T>` return types in all Repositories.

#### 23. [Architecture] Use `freezed` for Bloc States
- **Priority:** P3
- **Effort:** M
- **Module:** All Features
- **Problem:** Boilerplate code for `Equatable` states.
- **Suggested Direction:** Adopt `freezed` for union types in Bloc states (e.g., `Result.success`, `Result.error`).

#### 24. [Testing] Fix Noisy Tests
- **Priority:** P3
- **Effort:** S
- **Module:** Testing
- **Problem:** `SEVERE` logs appearing in successful test runs confuse debugging.
- **Suggested Direction:** Configure Logger to be silent during tests or mock it properly.

#### 25. [Testing] Add Golden Tests
- **Priority:** P3
- **Effort:** M
- **Module:** UI
- **Problem:** Visual regressions are hard to catch.
- **Suggested Direction:** Add `golden_toolkit` tests for `DashboardScreen` and `TransactionList`.

#### 26. [Architecture] Decouple AuthBloc from Supabase
- **Priority:** P3
- **Effort:** S
- **Module:** Auth
- **Problem:** `AuthBloc` might be depending directly on Supabase types/exceptions.
- **Suggested Direction:** Ensure `AuthRepository` abstracts all Supabase details.

#### 27. [Tech Debt] Optimize `GroupExpenseModel` Mapping
- **Priority:** P3
- **Effort:** S
- **Module:** Group Expenses
- **Problem:** Heavy mapping logic in `fromEntity`/`toEntity`.
- **Suggested Direction:** Profile performance. Consider caching or optimizing loops if lists are large.

#### 28. [Docs] Update README
- **Priority:** P3
- **Effort:** XS
- **Module:** Docs
- **Problem:** README likely outdated given the rapid development.
- **Suggested Direction:** Document the Architecture, Setup, and Sync mechanism.

#### 29. [Security] Validate Supabase Config
- **Priority:** P3
- **Effort:** XS
- **Module:** Core Network
- **Problem:** App might crash or behave weirdly if Keys are missing.
- **Suggested Direction:** Add strict validation in `AppBootstrap`.

#### 30. [Performance] Optimize Asset Loading
- **Priority:** P3
- **Effort:** S
- **Module:** UI
- **Problem:** SVG/Image assets might be large.
- **Suggested Direction:** Verify asset sizes. Use caching (already likely handled by Flutter, but verify).
