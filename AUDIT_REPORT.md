# Sprint Guru Audit Report

## Phase 1: Full Project Analysis

### 1. Architecture & State Management
- **Architecture**: The project follows a Clean Architecture approach (Presentation, Domain, Data layers), which is commendable. Feature-based folder structure is used effectively.
- **State Management**: `flutter_bloc` is used consistently across the app. This provides predictable state transitions and testability.
- **Dependency Injection**: `GetIt` is used for DI, which is standard and effective.

### 2. Backend & Data Integration (CRITICAL GAP)
- **Supabase Integration**: The project context specifies Supabase as the backend, but **no Supabase dependencies or implementation exist in the codebase**. This is a P0 critical gap.
- **Local Storage**: `hive_ce` is used for local storage. Models are tightly coupled to `HiveObject`.
- **Synchronization**: There is no synchronization logic. The "Outbox pattern" mentioned in project memory is missing from the implementation.

### 3. Feature Completeness
- **Expenses/Income/Budget**: Appears mostly complete with UI, Logic, and Data layers.
- **Groups**: The `groups` feature is skeletal (`lib/features/groups/presentation` exists but is empty). This feature is effectively unimplemented.
- **Settings/Data Management**: Implemented but relies solely on local Hive box export/import.

### 4. Testing & DevOps
- **Testing**: Good coverage with Unit, Widget, and Golden tests. Smoke tests are present in `ci/smoke`.
- **CI/CD**: CI scripts exist for code checks and smoke tests.
- **Linting**: Standard `flutter_lints` used.

### 5. Security
- **Authentication**: No authentication implementation found (relies on local device security).
- **RLS**: Not applicable yet as Supabase is missing, but will be critical once added.

---

## Phase 2: Grouping & Epics

### Epic 1: Core Backend Infrastructure (Supabase)
**Goal**: Establish the foundational connection to Supabase for Auth and Database.
- Add Dependencies
- Initialize Client
- Implement Auth (Sign Up, Sign In, Sign Out)
- Define Database Schema & RLS

### Epic 2: Data Synchronization Engine (Offline-First)
**Goal**: Enable seamless data sync between local Hive storage and Supabase using an Outbox pattern.
- Implement `OutboxItem`
- Create Sync Worker
- Update Repositories to write to Outbox

### Epic 3: Feature Implementation - Groups
**Goal**: Implement the missing Groups feature to allow social expense sharing.
- Domain Layer (Entities, UseCases)
- Data Layer (Repositories, DTOs)
- Presentation Layer (UI, Bloc)

### Epic 4: Technical Debt & Optimization
**Goal**: Address architectural couplings and performance risks.
- Decouple Models from Hive (partial)
- Optimize large list filtering
- Fix "Missing Backend" architectural violation

---

## Phase 3: Ticket Creation (Top 30)

### [P0] Add Supabase Dependencies & Configuration
- **Category**: Infrastructure
- **Priority**: P0
- **Effort Estimate**: S
- **Module Affected**: Core
- **Problem Statement**: The project lacks the required Supabase dependencies despite being designated as a Supabase project.
- **Root Cause Analysis**: Initial project setup missed backend integration.
- **Suggested Direction**: Add `supabase_flutter` to `pubspec.yaml`. Initialize `Supabase.initialize` in `main.dart` with environment variables.
- **Code References**: `pubspec.yaml`, `lib/main.dart`
- **Acceptance Criteria**: App compiles with Supabase dependency. `SupabaseClient` is accessible via GetIt.
- **Testing Recommendations**: Verify initialization in `main.dart`.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P0] Implement Supabase Authentication Repository
- **Category**: Security
- **Priority**: P0
- **Effort Estimate**: M
- **Module Affected**: Auth
- **Problem Statement**: No user authentication exists.
- **Root Cause Analysis**: Missing backend integration.
- **Suggested Direction**: Create `AuthRepository` interfacing with `Supabase.auth`. Implement `signIn`, `signUp`, `signOut`, `userStream`.
- **Code References**: `lib/core/data/repositories/auth_repository.dart` (New)
- **Acceptance Criteria**: Users can sign up and sign in. User session persists.
- **Testing Recommendations**: Integration tests with Supabase Auth.
- **Risk Level**: High (Security)
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P0] Define Supabase Database Schema
- **Category**: Backend
- **Priority**: P0
- **Effort Estimate**: M
- **Module Affected**: Backend
- **Problem Statement**: No database schema exists for Accounts, Expenses, etc.
- **Root Cause Analysis**: Missing backend.
- **Suggested Direction**: Create SQL migration scripts for: `profiles`, `accounts`, `categories`, `expenses`, `incomes`. Use UUIDs.
- **Code References**: `supabase/migrations/`
- **Acceptance Criteria**: Tables created in Supabase.
- **Testing Recommendations**: Manual verification in Supabase Dashboard.
- **Risk Level**: High
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P0] Implement RLS Policies
- **Category**: Security
- **Priority**: P0
- **Effort Estimate**: M
- **Module Affected**: Backend
- **Problem Statement**: Data must be isolated per user.
- **Root Cause Analysis**: Missing backend.
- **Suggested Direction**: Enable RLS on all tables. Create policies: `auth.uid() == user_id`.
- **Code References**: `supabase/migrations/`
- **Acceptance Criteria**: Users can only CRUD their own data.
- **Testing Recommendations**: SQL tests or integration tests with multiple users.
- **Risk Level**: Critical
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P0] Implement OutboxItem Entity & Hive Box
- **Category**: Architecture
- **Priority**: P0
- **Effort Estimate**: S
- **Module Affected**: Core/Sync
- **Problem Statement**: Offline changes need to be queued for sync.
- **Root Cause Analysis**: Missing sync strategy.
- **Suggested Direction**: Create `OutboxItem` (id, type, payload, action, timestamp). Register Hive adapter.
- **Code References**: `lib/core/sync/data/models/outbox_item.dart` (New)
- **Acceptance Criteria**: Can save/retrieve items from `outbox` Hive box.
- **Testing Recommendations**: Unit tests for Model/Adapter.
- **Risk Level**: Medium
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P0] Implement Synchronization Service (Worker)
- **Category**: Architecture
- **Priority**: P0
- **Effort Estimate**: L
- **Module Affected**: Core/Sync
- **Problem Statement**: No mechanism to push local changes to the cloud.
- **Root Cause Analysis**: Missing sync strategy.
- **Suggested Direction**: Create `SyncService`. Watch connectivity. On connect, process `outbox` queue FIFO. Handle conflicts (Client Wins or Server Wins).
- **Code References**: `lib/core/sync/services/sync_service.dart` (New)
- **Acceptance Criteria**: Offline changes sync to Supabase when online.
- **Testing Recommendations**: Integration tests mocking network state.
- **Risk Level**: High
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Refactor ExpenseRepository to Use Outbox
- **Category**: Refactoring
- **Priority**: P1
- **Effort Estimate**: M
- **Module Affected**: Expenses
- **Problem Statement**: Expenses are only saved locally.
- **Root Cause Analysis**: Missing sync integration.
- **Suggested Direction**: In `addExpense`, `updateExpense`, `deleteExpense`: write to local Hive box AND add an entry to `outbox` Hive box.
- **Code References**: `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- **Acceptance Criteria**: CRUD operations create Outbox items.
- **Testing Recommendations**: Unit verify Outbox write.
- **Risk Level**: Medium
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Refactor IncomeRepository to Use Outbox
- **Category**: Refactoring
- **Priority**: P1
- **Effort Estimate**: M
- **Module Affected**: Income
- **Problem Statement**: Income is only saved locally.
- **Root Cause Analysis**: Missing sync integration.
- **Suggested Direction**: Similar to ExpenseRepository, wrap writes with Outbox logic.
- **Code References**: `lib/features/income/data/repositories/income_repository_impl.dart`
- **Acceptance Criteria**: CRUD operations create Outbox items.
- **Testing Recommendations**: Unit verify Outbox write.
- **Risk Level**: Medium
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Implement Groups Domain Layer
- **Category**: Feature
- **Priority**: P1
- **Effort Estimate**: S
- **Module Affected**: Groups
- **Problem Statement**: Missing business logic for Groups.
- **Root Cause Analysis**: Incomplete feature.
- **Suggested Direction**: Create `Group` entity, `GroupRepository` interface, `CreateGroup`, `GetGroups` usecases.
- **Code References**: `lib/features/groups/domain/`
- **Acceptance Criteria**: Domain entities and interfaces defined.
- **Testing Recommendations**: Unit tests for usecases.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 3
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Implement Groups Data Layer
- **Category**: Feature
- **Priority**: P1
- **Effort Estimate**: M
- **Module Affected**: Groups
- **Problem Statement**: No data storage for Groups.
- **Root Cause Analysis**: Incomplete feature.
- **Suggested Direction**: Implement `GroupRepositoryImpl`. Use Supabase directly (groups are shared, so maybe less offline-first or optimistic UI).
- **Code References**: `lib/features/groups/data/`
- **Acceptance Criteria**: Can fetch/create groups from Supabase.
- **Testing Recommendations**: Integration tests.
- **Risk Level**: Medium
- **Sprint Recommendation**: Sprint 3
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Implement Groups Presentation (List & Create)
- **Category**: Feature
- **Priority**: P1
- **Effort Estimate**: M
- **Module Affected**: Groups
- **Problem Statement**: No UI for Groups.
- **Root Cause Analysis**: Incomplete feature.
- **Suggested Direction**: Create `GroupListScreen`, `CreateGroupScreen`. Use `Bloc` for state.
- **Code References**: `lib/features/groups/presentation/`
- **Acceptance Criteria**: User can see list of groups and create a new one.
- **Testing Recommendations**: Widget tests.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 3
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Implement Member Invitation Logic
- **Category**: Feature
- **Priority**: P1
- **Effort Estimate**: M
- **Module Affected**: Groups
- **Problem Statement**: Users cannot invite others to groups.
- **Root Cause Analysis**: Missing feature.
- **Suggested Direction**: Use Supabase Edge Functions or simple RLS insert to `group_invites` table.
- **Code References**: `supabase/functions/invite-user/`
- **Acceptance Criteria**: User B receives invite from User A.
- **Testing Recommendations**: Integration test.
- **Risk Level**: Medium
- **Sprint Recommendation**: Sprint 3
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Fix ExpenseModel Tight Coupling to Category
- **Category**: Tech Debt
- **Priority**: P1
- **Effort Estimate**: S
- **Module Affected**: Expenses
- **Problem Statement**: `ExpenseModel.toEntity` logic for fetching Category is complex and prone to errors if cache is missing.
- **Root Cause Analysis**: Direct dependency in mapping logic.
- **Suggested Direction**: Ensure `ExpenseModel` only stores `categoryId`. The Repository should handle the "Join" logic cleanly, possibly returning a `PopulatedExpense` or ensuring Category cache is hot.
- **Code References**: `lib/features/expenses/data/models/expense_model.dart`
- **Acceptance Criteria**: Simplified `toEntity` logic.
- **Testing Recommendations**: Unit tests for mapping.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P1] Implement Cloud Backup (Snapshot)
- **Category**: Feature
- **Priority**: P1
- **Effort Estimate**: M
- **Module Affected**: Settings
- **Problem Statement**: Current backup is local-only (JSON).
- **Root Cause Analysis**: Local-first design.
- **Suggested Direction**: Upload Hive box exports (JSON/Binary) to Supabase Storage bucket as a backup.
- **Code References**: `lib/features/settings/data/repositories/data_management_repository_impl.dart`
- **Acceptance Criteria**: "Backup to Cloud" button uploads file.
- **Testing Recommendations**: Integration test.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Add Error Handling for Sync Failures
- **Category**: UX
- **Priority**: P2
- **Effort Estimate**: S
- **Module Affected**: Sync
- **Problem Statement**: If sync fails (e.g., conflict), user is unaware.
- **Root Cause Analysis**: N/A (New feature).
- **Suggested Direction**: Add a "Sync Status" indicator. If error, allow user to retry or view log.
- **Code References**: `lib/core/widgets/sync_status_indicator.dart`
- **Acceptance Criteria**: Visual cue for sync errors.
- **Testing Recommendations**: Widget test.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Optimize ExpenseRepository Filtering
- **Category**: Performance
- **Priority**: P2
- **Effort Estimate**: S
- **Module Affected**: Expenses
- **Problem Statement**: `getExpenses` fetches *all* expenses then filters in Dart.
- **Root Cause Analysis**: Hive limitations (No complex queries).
- **Suggested Direction**: Maintain secondary indices (e.g., `expenses_by_account` Hive box) or optimize loop.
- **Code References**: `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- **Acceptance Criteria**: Faster filtering on large datasets.
- **Testing Recommendations**: Benchmark test.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 4
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Refactor DataManagementRepository
- **Category**: Refactoring
- **Priority**: P2
- **Effort Estimate**: S
- **Module Affected**: Settings
- **Problem Statement**: `DataManagementRepositoryImpl` has hardcoded box logic.
- **Root Cause Analysis**: Initial simple implementation.
- **Suggested Direction**: Inject a `LocalStorageService` abstraction instead of raw Hive boxes.
- **Code References**: `lib/features/settings/data/repositories/data_management_repository_impl.dart`
- **Acceptance Criteria**: Repository depends on interface.
- **Testing Recommendations**: Unit tests.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 4
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Add Unit Tests for Groups Feature
- **Category**: Testing
- **Priority**: P2
- **Effort Estimate**: S
- **Module Affected**: Groups
- **Problem Statement**: New feature requires tests.
- **Root Cause Analysis**: N/A.
- **Suggested Direction**: Add `group_bloc_test.dart`, `group_repository_test.dart`.
- **Code References**: `test/features/groups/`
- **Acceptance Criteria**: >80% coverage for groups.
- **Testing Recommendations**: Unit tests.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 3
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Add Integration Tests for Sync Logic
- **Category**: Testing
- **Priority**: P2
- **Effort Estimate**: M
- **Module Affected**: Sync
- **Problem Statement**: Sync is complex and critical.
- **Root Cause Analysis**: N/A.
- **Suggested Direction**: Use `integration_test` package. Simulate offline -> write -> online -> check server.
- **Code References**: `integration_test/sync_test.dart`
- **Acceptance Criteria**: Sync verified end-to-end.
- **Testing Recommendations**: Integration tests.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Add Offline Mode Indicator
- **Category**: UX
- **Priority**: P2
- **Effort Estimate**: XS
- **Module Affected**: Core/UI
- **Problem Statement**: User should know if they are offline.
- **Root Cause Analysis**: N/A.
- **Suggested Direction**: Listen to `connectivity_plus`. Show banner if offline.
- **Code References**: `lib/core/widgets/offline_banner.dart`
- **Acceptance Criteria**: Banner appears when airplane mode on.
- **Testing Recommendations**: Widget test.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 2
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P2] Standardize Error Messages
- **Category**: UX
- **Priority**: P2
- **Effort Estimate**: S
- **Module Affected**: Core
- **Problem Statement**: Error messages are inconsistent.
- **Root Cause Analysis**: Ad-hoc error handling.
- **Suggested Direction**: Create `AppError` class with localized user-friendly messages.
- **Code References**: `lib/core/error/failure.dart`
- **Acceptance Criteria**: Consistent error UI.
- **Testing Recommendations**: Review.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 4
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P3] Update README with Supabase Setup
- **Category**: Documentation
- **Priority**: P3
- **Effort Estimate**: XS
- **Module Affected**: Docs
- **Problem Statement**: README lacks backend setup info.
- **Root Cause Analysis**: Missing backend.
- **Suggested Direction**: Add "Supabase Setup" section (Env vars, migrations).
- **Code References**: `README.md`
- **Acceptance Criteria**: Clear instructions for new devs.
- **Testing Recommendations**: N/A.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 1
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

### [P3] Add Supabase Usage Metrics to Dashboard
- **Category**: Analytics
- **Priority**: P3
- **Effort Estimate**: S
- **Module Affected**: Dashboard
- **Problem Statement**: No visibility into sync status on dashboard.
- **Root Cause Analysis**: N/A.
- **Suggested Direction**: Add "Last Synced: 5m ago" widget.
- **Code References**: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- **Acceptance Criteria**: Visual sync timestamp.
- **Testing Recommendations**: Widget test.
- **Risk Level**: Low
- **Sprint Recommendation**: Sprint 4
- *Advisory: Suggested solution is directional. Developers must evaluate best frameworks, patterns, and implementation strategies before applying changes.*

---

## Phase 4: Technical Debt Dashboard

| Metric | Score | Notes |
| :--- | :--- | :--- |
| **Overall Project Health** | **65/100** | Strong foundational code, but critical missing backend infrastructure. |
| **Module Health: Core** | 80/100 | Clean architecture, good DI. |
| **Module Health: Features** | 70/100 | Most features good, but `Groups` is empty. |
| **Security Risk Score** | **High** | No Authentication or RLS currently implemented. |
| **Performance Risk Score** | Low | Local-first is fast; sync needs care. |
| **Architectural Consistency** | 90/100 | Strict adherence to Clean Architecture. |
| **Testing Maturity** | 85/100 | Comprehensive test suite available. |

### Top 5 Systemic Risks
1.  **Missing Backend**: The application is currently local-only despite requirements.
2.  **Data Synchronization**: Implementing robust 2-way sync is complex and error-prone.
3.  **Security**: Lack of Auth/RLS leaves future cloud data vulnerable.
4.  **Feature Gap**: Groups feature is completely missing.
5.  **Coupling**: Hive coupling in models requires careful abstraction for sync.

### Suggested Sprint Focus
**Sprint 1**: Focus entirely on **Epic 1 (Supabase Core)** and **Epic 2 (Sync Engine)**. Do not start new features until data layer is stabilized.
