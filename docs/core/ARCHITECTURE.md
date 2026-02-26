# System Architecture

## Overview
Expense Tracker is a **local-first, offline-capable** financial application built with Flutter. It prioritizes instant UI response by writing to a local database (Hive) first, then synchronizing with the backend (Supabase) in the background.

## Module Structure
The codebase follows a **Feature-First** architecture:

*   **`lib/core/`**: Shared utilities, widgets, and infrastructure (Network, DI, Theme).
*   **`lib/features/`**: Independent business modules (Auth, Transactions, Budgets, etc.).
    *   Each feature typically contains: `presentation/` (UI, Blocs), `domain/` (Entities, UseCases), `data/` (Repositories, Models, DataSources).

## State Management
*   **Pattern**: BLoC (Business Logic Component).
*   **Libraries**: `flutter_bloc`, `equatable`.
*   **Rule**: UI components (`Widgets`) should dispatch **Events** to Blocs and listen for **States**. Business logic must not reside in the UI.

## Data Layer & Synchronization
The system uses a sophisticated **Local-First Sync Strategy**:

1.  **Read Path**: UI always reads from **Hive** (Local DB).
2.  **Write Path**:
    *   UI writes to **Hive** immediately.
    *   Operation is queued in an **Outbox** (Hive box).
    *   **Sync Service** (Background) processes the Outbox and pushes to **Supabase**.
3.  **Remote Updates**:
    *   The app subscribes to **Supabase Realtime** channels.
    *   Incoming changes are written to **Hive**.
    *   UI updates automatically via Hive listeners (ValueListenableBuilder or Bloc streams).

### Key Components
*   **Hive**: NoSQL local database. Used for fast reads and offline storage.
*   **Supabase**: PostgreSQL backend. Handles Auth, RLS, and backup.
*   **GetIt**: Dependency Injection.

## Navigation
*   **Library**: `go_router`.
*   **Structure**: Defined in `lib/router.dart`.
*   **Deep Links**: Supported for Invites and specific Transaction views.
