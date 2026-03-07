# Feature Inventory

## Scope Summary

The 1.0.0 release contains 21 feature modules under `lib/features`, backed by shared infrastructure in `lib/core`, `lib/ui_kit`, and `lib/ui_bridge`.

## Core Finance Platform

### Accounts

**Description:** Manage asset accounts used as the source or destination of financial activity.  
**Purpose:** Give users a structured ledger context instead of storing transactions in a single undifferentiated pool.  
**Major components involved:** `accounts` feature, account Bloc flows, account forms, account cards, account selection widgets.

### Transactions

**Description:** Create, edit, inspect, sort, filter, and browse transaction history.  
**Purpose:** Provide the primary interaction surface for recording financial activity and reviewing prior entries.  
**Major components involved:** `transactions` feature, transaction list/detail pages, filter dialogs, calendar view, transaction entity/use cases.

### Expenses

**Description:** Record expense transactions with richer expense-specific metadata and split handling support.  
**Purpose:** Support detailed outgoing transaction capture, including collaborative and shared-spend scenarios.  
**Major components involved:** `expenses` feature, expense repository, expense models, split engine, add-expense wizard, expense cards.

### Income

**Description:** Track incoming funds independently from expenses.  
**Purpose:** Enable complete cash-flow visibility rather than expense-only accounting.  
**Major components involved:** `income` feature, income repository, income models, income cards, use cases.

## Financial Planning And Insight

### Categories

**Description:** Maintain predefined and user-defined spending and income categories, including history rules for categorization.  
**Purpose:** Organize transactions for reporting, budgeting, and automation.  
**Major components involved:** `categories` feature, category management Bloc, category picker/dialog widgets, merchant and keyword data assets.

### Budgets

**Description:** Create, review, and manage budget periods and spending limits.  
**Purpose:** Help users plan spending against explicit boundaries and monitor adherence.  
**Major components involved:** `budgets` feature, budget list/detail pages, budget repository, budget summary widgets.

### Goals

**Description:** Define savings goals, log contributions, and monitor progress over time.  
**Purpose:** Extend the app from retrospective tracking into forward-looking savings planning.  
**Major components involved:** `goals` feature, goal entities and use cases, contribution logging, goal detail and summary widgets.

### Reports

**Description:** Generate analytical views and exports covering category spend, time-based spend, income vs expense, budget performance, and goal progress.  
**Purpose:** Convert raw transaction history into actionable financial insight.  
**Major components involved:** `reports` feature, report filter Bloc, chart widgets, CSV export helpers, report pages.

### Analytics Dashboard

**Description:** Present high-level financial summaries, asset distribution, recent activity, and trend indicators.  
**Purpose:** Give users an operational overview immediately after launch.  
**Major components involved:** `dashboard` and `analytics` features, dashboard Bloc, summary widgets, charts, visual cards.

## Automation And Recurrence

### Recurring Transactions

**Description:** Define rules for repeating income and expense events, with generation on launch and audit tracking.  
**Purpose:** Reduce manual entry for subscriptions, salaries, and predictable bills.  
**Major components involved:** `recurring_transactions` feature, recurring rule repository, audit log model, generation service, recurring list and editor pages.

### Categorization Automation

**Description:** Apply merchant-aware and history-aware categorization signals to transaction flows.  
**Purpose:** Reduce repeated categorization work and improve consistency.  
**Major components involved:** merchant/category data assets, transaction merchant identifiers, category history rules, related data sources.

## Identity, Security, And User State

### Authentication

**Description:** Support user sign-in, verification, session checks, and logout through Supabase Auth.  
**Purpose:** Enable cloud-backed identity, collaborative features, and synchronized user data.  
**Major components involved:** `auth` feature, auth repository, login and verification pages, session Cubit, Supabase client provider.

### Profile Management

**Description:** Capture and synchronize user profile information, including profile setup and avatar upload flows.  
**Purpose:** Personalize the application and provide profile data for collaboration and group contexts.  
**Major components involved:** `profile` feature, local and remote profile data sources, profile Bloc, profile setup page.

### Device Security

**Description:** Protect local data using secure storage, encrypted Hive boxes, and biometric app lock flows.  
**Purpose:** Reduce exposure of sensitive financial data on shared or unlocked devices.  
**Major components involved:** secure storage service, auth lock screen, encrypted Hive initialization, settings security section.

## Collaboration And Shared Finance

### Groups

**Description:** Create and manage collaborative groups with membership and role semantics.  
**Purpose:** Enable shared financial contexts for households, trips, teams, or other expense-sharing scenarios.  
**Major components involved:** `groups` feature, groups repository, create-group flows, group detail/list pages, group membership Bloc.

### Group Expenses

**Description:** Record shared expenses inside collaborative groups.  
**Purpose:** Let users capture expenses that belong to a group context instead of a private ledger only.  
**Major components involved:** `group_expenses` feature, local and remote data sources, group expenses Bloc, add-group-expense page.

### Settlements

**Description:** Present settlement flows, including UPI-assisted settlement interaction.  
**Purpose:** Help users reconcile balances created by shared expenses.  
**Major components involved:** `settlements` feature, settlement entities, settlement dialog, UPI service.

### Deep Links And Invites

**Description:** Support invite-driven joining and route-aware deep-link handling.  
**Purpose:** Turn collaborative workflows into a usable onboarding loop rather than a manual admin-only process.  
**Major components involved:** `deep_link` feature, invite Supabase functions, router redirects, join-via-invite flow.

### Split Engine

**Description:** Compute shared expense splits using explicit payer and split entities.  
**Purpose:** Provide a deterministic foundation for collaborative expense distribution and settlement logic.  
**Major components involved:** `expenses` split entities, split engine domain utilities, related tests and repository integration.

## Configuration And System Management

### Settings

**Description:** Manage theme, appearance, security, backup/restore, and other app-level behaviors.  
**Purpose:** Centralize application customization and lifecycle management.  
**Major components involved:** `settings` feature, settings Bloc, data management flows, appearance and security sections.

### Backup And Restore

**Description:** Export and restore application data, including encrypted backup support introduced during hardening.  
**Purpose:** Provide user-controlled resilience for locally stored financial data.  
**Major components involved:** settings data management repository, backup/restore use cases, secure storage and encryption services.

### Demo Mode And Sample Data

**Description:** Provide demo mechanics and seeded recurring/demo states for non-production or preview use.  
**Purpose:** Support exploration, testing, and presentation workflows without requiring user-created data.  
**Major components involved:** demo data assets, dashboard/demo indicator widgets, demo refresh logic.

## Platform And Experience Layer

### Theme Packs And Visual Modes

**Description:** Offer multiple visual themes and palette systems, later unified behind UI Kit tokens and mode themes.  
**Purpose:** Differentiate the product visually and support consistent branding across modules.  
**Major components involved:** `aether_themes` feature, theme configs, app theme builders, UI Kit theme extension.

### UI Kit And Bridge Layer

**Description:** Provide a reusable design system and compatibility adapters for legacy components.  
**Purpose:** Standardize UI behavior, improve maintainability, and support ongoing migration without blocking delivery.  
**Major components involved:** `lib/ui_kit`, `lib/ui_bridge`, showcase page, contract and migration documentation.

### Multi-Platform Delivery

**Description:** Ship the application across Android, iOS, Web, Windows, macOS, and Linux from a shared Flutter codebase.  
**Purpose:** Maximize reach while keeping one primary product implementation.  
**Major components involved:** Flutter platform folders, web deployment pipeline, desktop plugin registrants, platform-aware initialization.
