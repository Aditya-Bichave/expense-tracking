# Known Issues

## Interpretation

This file captures realistic release risks and likely weak spots identified from the repository history. Items marked as inferred are not explicit open bugs in the commit log, but they are reasonable engineering concerns based on system complexity, recent stabilization patterns, and test surface concentration.

## 1. Auth bootstrap and Supabase initialization remain sensitive

**Status:** Observed from recent history  
**Why it matters:** The final release-day commits focused on Supabase initialization and router redirect behavior, which suggests app bootstrap and authenticated route gating were still active stabilization areas on March 7, 2026.  
**Impact:** Web startup, protected route access, and session restoration may remain the most likely source of early-release regressions.

## 2. Collaborative sync paths require continued soak testing

**Status:** Inferred from architecture and change volume  
**Why it matters:** Group membership, group expenses, deep links, realtime subscriptions, sync retries, and last-write-wins resolution all landed during a concentrated 2026 feature wave.  
**Impact:** Race conditions, stale state, or duplicate processing may still appear under poor connectivity or concurrent edits.

## 3. UI migration breadth increases regression risk

**Status:** Observed from history  
**Why it matters:** A large number of screens were migrated to the UI Kit and bridge layer in late February and early March 2026, touching dashboard, groups, expense wizard, reports, auth, profile, and settings.  
**Impact:** Visual consistency is much stronger, but low-frequency interaction bugs and layout regressions across platforms remain plausible.

## 4. Web deployment has multiple supported paths, which can drift

**Status:** Inferred from infrastructure shape  
**Why it matters:** The repository supports GitHub Actions publication, Node hosting, Docker/Nginx, and Vercel-style output. The generated `server/public` directory is committed back to the repository.  
**Impact:** If teams do not standardize on one deployment path, the published artifact and source state can diverge, making rollback and verification harder.

## 5. Encrypted local storage recovery is protective but destructive

**Status:** Observed from application behavior  
**Why it matters:** The app includes corruption recovery for Hive encryption keys by clearing secure storage and local boxes.  
**Impact:** Recovery protects availability, but data loss is possible on corrupted local stores when cloud sync or backup is not current.

## 6. Automated end-to-end coverage is web-focused

**Status:** Observed from repository assets  
**Why it matters:** The strongest end-to-end automation in the repository targets Flutter web through Playwright.  
**Impact:** Android, iOS, and desktop platform-specific regressions may not be caught by the same level of automation before release.

## 7. Accessibility improvements exist, but accessibility is not yet comprehensively validated

**Status:** Inferred from history  
**Why it matters:** The commit history includes accessibility-focused enhancements, but there is no evidence of a full accessibility audit pipeline.  
**Impact:** Keyboard, screen reader, contrast, and focus-management issues may still exist in less commonly used screens.

## 8. Backup, restore, and security features need platform-specific confidence

**Status:** Inferred from capability complexity  
**Why it matters:** Backup, restore, secure storage, app lock, and encrypted Hive behavior depend on platform integration details.  
**Impact:** Cross-platform edge cases may still appear even if Flutter-layer tests pass.

## 9. Performance has been actively optimized, but high-data scenarios should continue to be monitored

**Status:** Observed from history  
**Why it matters:** The team invested heavily in eliminating linear scans, repeated formatter construction, and inefficient list rendering.  
**Impact:** This indicates known performance pressure. Larger real-world datasets may still reveal hotspots, especially in reports, dashboards, and transaction-heavy views.

## 10. Generated and codegen-backed assets remain a maintenance risk

**Status:** Inferred from repository structure  
**Why it matters:** The system depends on generated Hive adapters, JSON serialization, compiled web artifacts, and CI-generated expectations around lockfiles and route data.  
**Impact:** Skipping code generation or publishing stale artifacts can create failures that appear only in CI or deployment.

## Recommended Follow-Up After 1.0.0

- Monitor auth bootstrap and router redirects in production-like web environments.
- Track sync behavior for group collaboration under intermittent connectivity.
- Continue expanding automated UI migration regression tests, especially on mobile targets.
- Standardize one primary deployment path for production operations.
- Perform focused soak testing for backup/restore and secure storage behavior on Android and iOS.
