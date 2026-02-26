# Phase 2 Integration QA Checklist

This document outlines the validation steps for Phase 2A (Groups + Realtime + Outbox) and Phase 2B (Invites + Deep Links + RBAC) integration.

## Integration Test Matrix

### 1. Multi-device Realtime Groups
- **Scenario**: Device A creates a group online.
- **Expected**:
  - Group appears instantly on Device A (Hive updated).
  - Group appears on Device B without manual refresh (via Realtime).
  - `updated_at` timestamps are consistent.
  - No duplicate groups.

### 2. Offline Group Creation + Outbox Flush
- **Scenario**:
  - Airplane mode ON.
  - Create group on Device A.
  - Verify group appears in UI with "Syncing..." indicator.
  - Airplane mode OFF.
- **Expected**:
  - Outbox item is processed within ~5 seconds.
  - Group exists on Supabase.
  - Other devices receive the group via Realtime.
  - Sync status becomes "Synced".
  - No duplicates created.

### 3. Deep Link Join (Logged Out)
- **Scenario**:
  - User taps `https://spendos.app/join?token=...` or `spendos://join?token=...`.
  - App opens from cold start (logged out).
- **Expected**:
  - Anonymous sign-in occurs automatically.
  - Overlay "Securing your invite..." appears.
  - `join_group_via_invite` succeeds.
  - User lands in the correct Group Dashboard.
  - Group appears in the groups list immediately.

### 4. Deep Link Join (Logged In)
- **Scenario**: User taps invite link while already logged in.
- **Expected**:
  - App opens/resumes.
  - Join process succeeds without re-authentication.
  - User is routed to the new group.

### 5. RBAC Enforcement
- **Scenario**:
  - Admin generates a "Viewer" invite.
  - User B joins using that invite.
- **Expected**:
  - User B sees the group as a Viewer.
  - "Add Expense", "Settlement", and Admin Settings are hidden/disabled for User B.
  - Realtime updates to role (e.g., Admin promotes Viewer to Member) reflect instantly in UI.

### 6. Member Management
- **Scenario**: Admin changes a member's role or kicks a member.
- **Expected**:
  - **Role Change**: Member's UI updates permissions instantly (Realtime).
  - **Kick**: Member loses access immediately; group disappears from their list (Realtime/Local cleanup).
  - Hive cache is updated accordingly.

## Manual QA Script

1.  **Setup**: Two devices (or simulators) logged in with different accounts.
2.  **Step 1 (Offline Create)**:
    - Device A: Go offline. Create "Offline Group". Check UI.
    - Device A: Go online. Wait for sync.
    - Device B: Verify "Offline Group" appears.
3.  **Step 2 (Invite & Join)**:
    - Device A (Admin): Go to Group Settings -> Members -> Invite. Copy Link.
    - Device B: Logout. Close App.
    - Device B: Open Deep Link. Verify Anonymous Login + Join.
4.  **Step 3 (Role Change)**:
    - Device A: Change Device B's role to "Viewer".
    - Device B: Verify "Add Expense" button disappears.
5.  **Step 4 (Kick)**:
    - Device A: Remove Device B from group.
    - Device B: Verify group disappears from list.

## Configuration Requirements
- **Deep Links**: Ensure `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` (or Entitlements) are configured for `spendos` scheme and `spendos.app` domain.
- **Supabase**: Ensure Edge Functions `create-invite` and `join_group_via_invite` are deployed.
