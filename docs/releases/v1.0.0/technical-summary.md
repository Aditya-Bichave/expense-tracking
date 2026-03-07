# Technical Summary

## System Overview

Expense Tracker 1.0.0 is a Flutter-based financial application built as a local-first system with optional cloud synchronization and collaborative workflows. The release spans the repository history from April 2, 2025 to March 7, 2026 and culminates in a feature-complete product baseline that combines personal finance management, shared expense flows, security controls, analytics, and a reusable design system.

At release time, the codebase contains:

- 21 feature modules under `lib/features`
- 7 Supabase migration files under `supabase/migrations`
- 473 test files under `test`
- Dedicated smoke and E2E automation under `ci/smoke` and `ci/e2e`

## Release Evolution

### Phase 1: Personal finance foundation (April 2025)

The first development wave established the single-user application surface:

- Settings and themes
- Category management
- Budgets and goals
- Reporting
- Demo mechanics

This phase created the product identity as a finance tracker rather than a generic Flutter starter.

### Phase 2: Recurrence, quality, and operational maturity (August 2025)

The second wave introduced recurring transaction support and a large body of validation, state, and UI fixes. It also marked the beginning of systematic CI investment, automated testing expansion, and stricter engineering discipline.

### Phase 3: Cloud, sync, collaboration, and security (January to February 2026)

The largest architectural shift arrived in early 2026:

- Supabase auth and configuration
- Local-first sync queue and realtime services
- Groups and shared expense infrastructure
- Profile management
- Secure storage, app lock, and encrypted Hive
- Invite flows and deep-link onboarding
- Deployment automation and web hosting infrastructure

This phase turned the app from a local finance utility into a distributed system.

### Phase 4: Hardening, performance, and UI platformization (late February to March 2026)

The final phase focused on release readiness:

- Broad defect-reduction campaigns
- Coverage expansion
- Performance optimization sweeps
- UI Kit extraction and app-wide migration
- Bridge layer for legacy-to-kit interoperability
- Web E2E automation
- Final fixes for pipeline, bootstrap, and profile stability

## Architecture Summary

## Feature-first structure

The repository follows a feature-first Flutter architecture:

- `lib/core`: shared infrastructure, configuration, services, sync, theme, routing support, and utilities
- `lib/features`: domain-specific modules grouped by business capability
- `lib/ui_kit`: design tokens and reusable UI components
- `lib/ui_bridge`: adapters used to migrate legacy UI incrementally without breaking compatibility

Most feature modules use a layered structure:

- `presentation`: pages, widgets, Blocs, and UI orchestration
- `domain`: entities, repositories, use cases, and domain utilities
- `data`: models, repositories, and local/remote data sources

## State management

The application uses the Bloc ecosystem:

- `flutter_bloc`
- `bloc`
- `equatable`
- `bloc_test` in testing

The history shows repeated effort to keep business logic out of widgets and inside Bloc or use-case layers.

## Dependency injection

Dependency injection is managed with GetIt. The repository includes feature-specific service configuration files for accounts, analytics, auth, budgets, categories, dashboard, data management, expenses, goals, groups, group expenses, income, profile, recurring transactions, reports, settings, and sync-related services.

## Data model and storage strategy

## Local-first data flow

The most important technical decision in the system is its local-first model:

1. UI reads from Hive-backed local stores.
2. Writes are applied locally first for immediate response.
3. Mutations are queued into an outbox/sync mutation store.
4. Sync services forward mutations to Supabase.
5. Realtime subscriptions apply remote changes back into local storage.

This model prioritizes responsiveness and offline tolerance over a purely server-authoritative interaction pattern.

## Local persistence

Hive CE is used for structured local persistence. The release stores numerous domain objects locally, including:

- Expenses
- Accounts
- Income
- Categories
- User history rules
- Budgets
- Goals and goal contributions
- Recurring rules and recurring rule audit logs
- Sync mutations/outbox entries
- Groups and group members
- Group expenses
- Profiles

Secure storage is used to retrieve or generate encryption keys for Hive AES encryption.

## Remote services

Supabase is used for:

- Authentication
- Database-backed synchronized data
- Realtime updates
- Row-level security
- Invite-related functions

The repository also contains Supabase migrations, RLS definitions, and edge/serverless function code for invite acceptance and joining flows.

## Major Modules

### Finance modules

- `accounts`
- `transactions`
- `expenses`
- `income`
- `categories`
- `budgets`
- `goals`
- `reports`
- `dashboard`
- `analytics`
- `recurring_transactions`

### Identity and system modules

- `auth`
- `profile`
- `settings`
- `deep_link`

### Collaboration modules

- `groups`
- `group_expenses`
- `settlements`

### Experience and styling modules

- `aether_themes`
- `add_expense`
- `budgets_cats`
- UI Kit and bridge layers outside `lib/features`

## Navigation And Routing

Navigation is built on `go_router`.

The routing layer supports:

- Shell-based navigation across major app tabs
- Protected routes informed by auth and session state
- Deep links for collaborative invite entry
- Detail/edit pages for finance entities
- UI Kit showcase routes

Repeated routing fixes in the history show that navigation correctness became especially important once auth and deep links were added.

## Key Dependencies

Important release dependencies include:

- `flutter_bloc` and `bloc`
- `hive_ce` and `hive_ce_flutter`
- `get_it`
- `go_router`
- `supabase_flutter`
- `flutter_secure_storage`
- `connectivity_plus`
- `google_fonts`
- `flutter_svg`
- `fl_chart`
- `shared_preferences`
- `file_picker`
- `local_auth`
- `share_plus`
- `flutter_timezone`
- `image_picker`
- `flutter_image_compress`
- `country_code_picker`
- `rxdart`

These dependencies align closely with the release history: state management, local persistence, auth/sync, UI richness, reporting, and platform integrations all expanded substantially over time.

## Testing Strategy

The testing posture is one of the strongest aspects of the release.

### Unit and widget tests

The repository includes 473 test files in `test`, covering:

- Domain entities and use cases
- Repositories and data sources
- Bloc state transitions
- Widgets and pages
- Integration flows
- Golden baselines
- UI Kit components

### Golden tests

Golden testing is present for UI regression coverage, including budget summary output.

### Smoke tests

`ci/smoke` hosts a Playwright-based smoke suite that:

- Serves the built web app locally
- Measures startup time
- Verifies major routes
- Captures console and page errors
- Produces screenshots and trace artifacts on failure

### E2E tests

`ci/e2e` hosts authenticated Playwright tests that:

- Pre-authenticate through Supabase credentials in global setup
- Inject session state into browser storage
- Exercise auth, dashboard, transactions, and report paths
- Produce browser reports, traces, videos, and screenshots

### Coverage enforcement

The current CI pipeline enforces:

- Diff coverage threshold via `diff-cover`
- Total coverage threshold of 50%

The history shows that test coverage growth was not incidental; it was a recurring engineering objective.

## CI/CD Setup

The current GitHub Actions pipeline includes the following major jobs:

- Static checks and policy enforcement
- Unit tests and coverage
- Web release build and bundle-size validation
- Smoke tests against built artifacts
- Authenticated web E2E tests
- PR report generation

Additional workflows exist for:

- Automatic web artifact publication to `server/public`
- Supabase migration validation

This is a notably mature setup for a first release and reflects a deliberate shift toward release discipline in 2026.

## E2E And Delivery Infrastructure

## Web hosting

The repository supports multiple web delivery models:

- Repository-published static assets in `server/public`
- Express-based Node hosting via `server/server.js`
- Docker + Nginx packaging
- Vercel output routing

## Supabase backend assets

The repository contains:

- Supabase migration scripts
- RLS policy files
- Invite-related functions
- Configuration for Supabase CLI validation

## Developer Tooling

The codebase includes tooling for:

- Code generation checks
- Lockfile checks
- New-code policy checks
- Bundle-size reporting
- PR comment generation
- Local deploy/test helper scripts
- Release smoke and E2E scripts

The documentation set under `docs/core`, `docs/governance`, and UI Kit references also indicates an increasingly structured engineering process by the end of the release cycle.

## Build System

## Flutter build

Primary application builds are standard Flutter builds, with web builds receiving the most operational attention.

## Server build

The hosted web path uses:

- Flutter build output copied into `server/public`
- Express for simple Node hosting or Nginx for containerized hosting

## Code generation

The project relies on `build_runner`, Hive generator support, and JSON serialization generation. Generated file consistency is checked in CI for pull requests.

## Performance Considerations

Performance work is a visible theme in the 1.0.0 history. Major patterns include:

- Replacing repeated linear scans with cached or indexed lookups
- Reducing object churn in loops and local data source operations
- Optimizing report filtering and budget calculations
- Improving transaction list rendering and startup behavior
- Benchmarking expense filtering behavior explicitly

The volume of performance commits suggests the team encountered real scaling pressure and addressed it before the first release.

## Operational Risks

The most important technical risks entering 1.0.0 are:

- Auth/bootstrap sensitivity due to recent initialization fixes
- Complexity in local-first collaborative sync behavior
- Broad UI migration surface area
- Potential drift between source and committed static artifacts
- Web-heavy end-to-end validation relative to mobile and desktop targets

## Conclusion

Expense Tracker 1.0.0 is not a lightweight first release. It is the result of nearly a year of incremental feature delivery followed by a concentrated period of architecture expansion, operational hardening, and UI platformization. The system is strongest where the history shows repeated engineering attention: local-first data handling, web delivery, automated testing, and design-system standardization. The primary follow-on concern for future releases is not missing core product capability, but managing the complexity now present in sync, collaboration, and cross-platform behavior.
