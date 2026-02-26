# Sync Rules

1. **Local First**: Write to Hive first.
2. **Outbox**: Queue  (create/update/delete) in Hive.
3. **Sync Service**: Process Outbox when online (FIFO).
4. **Realtime**: Subscribe to Supabase changes and update local Hive cache (Last-Write-Wins based on ).
