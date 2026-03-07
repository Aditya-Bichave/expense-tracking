# Changelog

All notable changes to this product are documented in this file.

The format is based on Keep a Changelog.

## [1.0.0] - 2026-03-07

### Added

- Multi-account finance management with dedicated account, expense, income, and transaction workflows.
- Custom categories, budget planning, savings goals, and contribution tracking.
- Analytics and reporting pages for category spend, spending trends, income vs expense, budget performance, and goal progress.
- Recurring transaction rules, launch-time generation, and recurring audit logs.
- Supabase authentication flows including OTP, magic link, session management, and profile setup.
- Biometric app lock, secure storage integration, and encrypted Hive persistence.
- Local-first synchronization primitives including outbox queueing, sync coordinator, realtime listeners, and retry/backoff logic.
- Group collaboration workflows including group creation, membership, shared expenses, settlements, invite generation, and deep-link based joining.
- Split expense engine with payer and split entities plus dedicated split calculation logic.
- Merchant-aware transaction metadata and auto-categorization support.
- UI Kit design system with tokens, reusable components, showcase, migration contract, and bridge adapters.
- Golden tests, smoke tests, and Playwright E2E coverage for authenticated web flows.

### Changed

- Evolved the application from a local personal tracker into a cloud-connected, local-first financial platform.
- Refactored sync payload modeling from early outbox items into typed sync mutations.
- Reworked routing to support auth-aware redirects, deep links, collaborative flows, and design system showcase routes.
- Migrated large areas of the UI from ad hoc styling to tokenized design system components.
- Improved form validation, category handling, report filters, dashboard loading behavior, and transaction filter placement.
- Upgraded test scope across domain, data, presentation, widget, and integration layers.
- Expanded deployment topology from local/web builds to GitHub Actions publication, Render-style hosting, Docker/Nginx packaging, and Vercel output support.

### Fixed

- Corrected recurring transaction drift, missing monthly day handling, and propagation of generation failures.
- Fixed budget overlap detection and budget detail month handling.
- Resolved category update validation failures, duplicate name handling, and category mapping edge cases.
- Fixed state rollback issues on failed deletes and several Bloc coordination defects.
- Resolved null-safety and async reliability issues across sync, group, and dashboard flows.
- Fixed auth and routing regressions including login navigation, shell route checks, deep-link handling, and final Supabase initialization defects.
- Addressed Hive corruption recovery and encrypted key handling failures.
- Stabilized the profile page in the final release window.
- Resolved numerous CI, smoke, and widget test failures encountered during rapid feature expansion and UI migration.

### Infrastructure

- Added GitHub Actions CI with formatting, analysis, policy, codegen, coverage, bundle-size, smoke, and E2E quality gates.
- Added automated web artifact publication to `server/public`.
- Added Supabase workflow validation for schema changes.
- Added Dockerfile and Nginx configuration for containerized web deployment.
- Added Express-based static server with client log ingestion for hosted web builds.
- Added PR report generation and artifact publishing in CI.
- Added deployment helper scripts and hosting configuration for Render/Vercel-style targets.

### Performance

- Optimized transaction lookup by date from linear scans to indexed access patterns.
- Reduced repeated allocations and lookups in local data sources and report filters.
- Optimized batch categorization and batch deletion flows.
- Improved budget performance calculations and transaction calendar map generation.
- Parallelized Hive box opening during startup.
- Reduced expensive UI list behavior, including `shrinkWrap` heavy paths and transaction list rendering overhead.
- Added benchmark coverage for expense filtering performance.
