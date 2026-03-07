# Release Notes

## Release Overview

**Version:** 1.0.0  
**Release date:** March 7, 2026

Expense Tracker 1.0.0 is the first formal release of the product and represents the full development history of the repository from April 2, 2025 through March 7, 2026. Over 213 commits, the application evolved from a local personal expense tracker into a multi-platform financial system with local-first storage, offline support, collaborative group expenses, Supabase-backed authentication and synchronization, a dedicated design system, and a production-oriented delivery pipeline.

This release packages the full product surface that emerged across that timeline into a single supported baseline for future releases.

## Product Highlights

### Personal finance management foundation

The release delivers the core capabilities expected from a serious expense management application:

- Multi-account financial tracking
- Income and expense capture
- Transaction editing, filtering, sorting, and calendar views
- Category management with custom category support
- Budgets and budget detail views
- Savings goals with contribution tracking
- Analytics dashboard and report exports
- Recurring transaction management

### Local-first architecture with cloud-backed sync

The application is built around a local-first model rather than a server-dependent interaction pattern:

- Hive is the primary read and write surface for the UI
- Mutations are queued into an outbox for background synchronization
- Supabase provides authentication, persistence, realtime updates, and access control
- Realtime subscriptions and retry logic were added to keep group and profile data aligned without sacrificing offline responsiveness

This architectural choice is one of the defining characteristics of the 1.0.0 release.

### Collaboration and shared expense workflows

What began as a single-user finance application expanded into collaborative financial workflows during the 2026 development cycle:

- Group creation and membership management
- Invite generation and deep-link based joining
- Shared group expenses
- Settlement workflows
- Split calculation support for expense sharing
- Realtime synchronization for collaborative state

### Security and identity

The release introduces a full identity and device security layer:

- Supabase Auth integration
- Phone OTP and email magic link sign-in flows
- Session management and resume checks
- Biometric app lock support
- Secure storage backed encryption keys for Hive boxes
- Profile setup and profile synchronization

### Production-grade quality pipeline

The repository history shows a substantial investment in release discipline before 1.0.0:

- Strict GitHub Actions CI pipeline
- Formatting, analysis, and policy gates
- Coverage enforcement
- Golden tests
- Web smoke tests
- Authenticated Playwright E2E coverage
- Automated web build publication
- Supabase migration validation

## Major Features Introduced

## 1. Accounts, transactions, and transaction workflows

The product matured from simple expense entry into a more complete transaction system:

- Dedicated account management
- Expense and income entry flows
- Add/edit transaction pages
- Transaction detail pages
- Transaction filtering and sorting improvements
- Calendar-based transaction views
- Merchant-aware transaction metadata and auto-categorization support

## 2. Categories, budgets, goals, and reports

A major early milestone expanded the app from raw transaction logging into guided financial planning:

- Custom categories
- Budget creation and overlap handling
- Goal creation, update, archival, and contribution logging
- Multiple report views including spending by category, spending over time, income vs expense, budget performance, and goal progress
- CSV export support for report data

## 3. Recurring transactions

Recurring financial activity became a first-class domain:

- Recurring rule management screens
- Recurring rule validation and monthly date handling
- Audit logging for recurring activity
- Launch-time transaction generation
- Reliability fixes for drift, missing fields, and reset handling

## 4. Authentication, profile, and security

The release includes a full user identity surface:

- Login and verification flows
- Lock screen support
- Profile setup and profile repository
- Secure storage integration
- Local data encryption key management
- App initialization fallback UI for corruption or bootstrap failure scenarios

## 5. Shared finance and social growth loops

The group collaboration work introduced a second major product dimension:

- Group list, detail, and creation flows
- Membership state and role handling
- Invite generation and invite acceptance services
- Join-via-invite deep links
- Group expense recording
- Settlement dialog and UPI support

## 6. UI Kit and visual system migration

A major late-stage initiative created a reusable design system and migrated the app onto it:

- Reusable UI Kit components across buttons, inputs, lists, charts, typography, feedback, loading, and layout
- Theme tokens for colors, spacing, radii, shadows, motion, and typography
- Bridge layer for migrating legacy widgets without blocking feature work
- Showcase and documentation for design system usage
- Migration of dashboard, groups, expense wizard, reports, profile, settings, and auth flows to the design system

## Key Improvements

### Reliability and correctness

- Hardened sync queue behavior with retry and exponential backoff
- Improved null-safety and async reliability in major flows
- Added corruption recovery path for encrypted local storage
- Stabilized router behavior for auth, deep links, and settings-driven updates
- Fixed state rollback behavior on failed delete operations
- Improved recurring transaction generation correctness

### Usability and accessibility

- Added required field indicators in forms
- Improved report responsiveness
- Added auditory feedback in parts of the reporting experience
- Expanded visual indicators, empty states, and loading feedback
- Improved login navigation, including back button behavior in auth flows

### Delivery and deployment

- Introduced Docker and Nginx packaging for Flutter web
- Added Node-based server hosting for deployed web artifacts
- Added GitHub Actions based web build publication to `server/public`
- Added Vercel output configuration and deployment corrections
- Added local deployment helper scripts near release stabilization

## Important Bug Fixes

The final release history includes a sustained stabilization effort across late February and early March 2026. The most important fixes included:

- Supabase initialization and router redirect failures that affected web bootstrap
- Profile page defects addressed in the final commit sequence
- Deep-link and group navigation correctness issues
- Demo mode refresh and recurring rule demo data problems
- Hive corruption and encrypted key recovery issues
- Null-safety defects and async timing races in sync and UI layers
- Budget date handling and overlap detection issues
- Category validation and mapping edge cases
- CI flakiness and smoke test instability

## High-Level Technical Improvements

- Feature-first Flutter architecture reinforced across 21 feature modules
- Dependency injection standardized with GetIt service configurations
- Local-first synchronization model formalized with dedicated sync models and services
- Security model extended with secure storage, encrypted Hive, auth sessions, and RLS-backed Supabase access control
- Test surface expanded to 473 repository test files, plus smoke and E2E suites
- Design system extracted and documented for long-term maintainability

## Engineering Timeline Summary

### April 2025

The project established its core personal finance workflows: settings, themes, categories, budgets, goals, reports, and demo mechanics.

### August 2025

Recurring transactions were added, followed by a long run of correctness fixes, dependency cleanup, and the first CI workflow.

### January to February 2026

The product entered a systems phase: performance work, merchant-aware categorization, stricter quality gates, Dockerized web delivery, Supabase auth, local-first sync, groups, deep links, profile management, security features, and deployment automation.

### Late February to March 2026

The app underwent broad hardening and UI modernization: stability passes, performance sweeps, coverage expansion, UI Kit extraction, bridge-layer rollout, feature migration to the design system, E2E automation, and last-mile fixes for pipeline, Supabase initialization, and profile behavior.

## Release Outcome

Version 1.0.0 establishes Expense Tracker as a production-ready, multi-platform financial application with both personal and collaborative finance capabilities, a defensible architecture, and the operational scaffolding needed for repeatable future releases.
