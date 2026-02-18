# Sync Rules

## Architecture
- **Local First**: All writes go to local Hive cache first, then queued to Outbox.
- **Outbox Pattern**: Changes are stored as OutboxItem with entityType, opType, and payload.
- **Sync Service**:
  - Processes pending items in order.
  - Pushes to Supabase via RPC or Table API.
  - On success, marks item as sent (or deletes).
  - On failure, increments retryCount. After max retries, marks failed.

## Conflict Resolution
- **Last Write Wins**: Based on updated_at.
- **Server Authority**: If server has a newer updated_at, local changes are overwritten during sync/pull.
- **Optimistic UI**: UI reflects local state immediately. Reverts on sync failure if critical.

## Realtime
- Subscriptions on expenses, settlements, group_members tables.
- INSERT/UPDATE/DELETE events trigger local cache update.
- Incoming changes are merged into Hive.
