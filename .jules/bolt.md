## 2026-02-06 - [Batch Operations in Clean Architecture]
**Learning:** Repositories iterating over child entities to perform individual delete/update operations (N+1) are common. Hive supports `deleteAll` for batch removal, which is significantly more efficient than loop-delete.
**Action:** When implementing `delete` for aggregates (like Goal -> Contributions), always ensure the Datasource exposes a batch delete method to avoid loop-overhead.
