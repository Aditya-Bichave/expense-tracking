# Bug Fix Log

## Overview

The repository history contains sustained defect-correction work across August 2025 through March 2026. The fixes below focus on product-significant bugs and release-relevant engineering corrections rather than formatting-only or low-signal cleanup commits.

## Authentication, Session, And Initialization Fixes

- Resolved multiple Supabase initialization defects during the final March 7, 2026 release window.
- Corrected router redirect behavior tied to authentication bootstrap and protected route handling.
- Added back button support in login and OTP verification flows to fix auth navigation dead ends.
- Hardened session checks on app resume and settings-driven router reactivity.
- Fixed profile page behavior in the final pre-release commit and expanded related web E2E coverage.

## Local Storage, Encryption, And Data Integrity Fixes

- Added recovery handling for Hive key corruption to prevent permanent startup lock-out.
- Fixed TypeId conflicts and model registration problems introduced during storage and profile expansion.
- Corrected backup and restore flows, later extending them with encrypted backup behavior.
- Fixed state restoration and reset handling for recurring rules and broader settings/data-management flows.
- Corrected date handling and payload parsing issues in sync and recurring data models.

## Sync, Collaboration, And Realtime Fixes

- Improved sync queue processing with exponential backoff and more robust retry behavior.
- Corrected race conditions and error flicker in realtime group synchronization.
- Added safer delete handling, last-write-wins logic for group member updates, and improved sync error reporting.
- Fixed collaboration issues in group joins, invite-driven onboarding, and group membership surfaces.
- Addressed shared-expense integration issues during Phase 2 and Phase 3 collaboration work.

## Transactions, Categories, And Recurring Logic Fixes

- Fixed recurring monthly date drift and missing `dayOfMonth` handling.
- Ensured future recurring rules are ignored when generation should not occur.
- Corrected propagation of failures during recurring transaction generation.
- Fixed category update validation so invalid non-custom category updates fail correctly.
- Corrected category confirmation and mapping behavior in early category refinement work.
- Added unique category name enforcement to prevent duplicate custom categories.
- Fixed transaction filtering defaults, filter dialog Bloc registration, and form state persistence issues.
- Added merchant identifier support and follow-up fixes for transaction auto-categorization.

## Budget, Goal, And Report Fixes

- Fixed budget overlap detection across recurring and one-time periods.
- Corrected budget detail month handling and performance calculations.
- Fixed contribution success flow after goal achievement checks.
- Added cache auditing and later optimized goal deletion with batch contribution removal.
- Fixed report filter scope so filters remain page-specific instead of leaking across report views.
- Corrected report responsiveness and export-related behavior as reporting matured.

## UI, UX, And Accessibility Fixes

- Added required-field indicators and several accessibility-oriented UI enhancements.
- Fixed missing or inconsistent loading feedback in transaction and dashboard flows.
- Resolved profile, settings, auth, and expense wizard regressions introduced during the UI Kit migration.
- Removed unsafe hard-coded styling and stabilized components after migration to tokenized UI primitives.
- Fixed demo mode refresh behavior, Create Group affordances, and recurring demo data setup.

## Performance And Stability Defects

- Optimized expensive date lookups, list rendering, report filtering, and calendar map creation to eliminate avoidable O(N) behavior.
- Reduced repeated formatter instantiation and repeated string splitting in hot paths.
- Fixed startup inefficiencies by parallelizing Hive box opening and reducing blocking initialization work.
- Stabilized dashboard loading by removing problematic cross-Bloc loading patterns.
- Corrected null-safety and async reliability issues surfaced during late-February hardening rounds.

## CI, Test, And Release Pipeline Fixes

- Repaired multiple CI failures involving formatting, analyzer issues, missing lockfiles, and reporting permissions.
- Increased smoke test time budgets and hardened smoke route verification to reduce false failures.
- Fixed route extraction, dashboard tests, and Google Fonts behavior in CI.
- Corrected coverage failures through targeted unit, widget, golden, and integration tests.
- Added Playwright E2E automation after the profile fix to increase release confidence on authenticated web flows.

## Final Release Stabilization Cluster

The final release window on March 7, 2026 concentrated on ship-readiness rather than new product surface:

- Pipeline fixes and local deployment helpers
- Supabase initialization corrections
- Router redirect test expansion
- Profile page fixes
- Authenticated web E2E setup and workflow integration

This pattern indicates that the project reached feature completeness before the final day and used the closing commits primarily to remove release blockers.
