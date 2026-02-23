## 2026-02-06 - [Batch Operations in Clean Architecture]
**Learning:** Repositories iterating over child entities to perform individual delete/update operations (N+1) are common. Hive supports `deleteAll` for batch removal, which is significantly more efficient than loop-delete.
**Action:** When implementing `delete` for aggregates (like Goal -> Contributions), always ensure the Datasource exposes a batch delete method to avoid loop-overhead.


## 2026-02-23 - Performance Optimization Pass

**Learning:** `ListView.separated(shrinkWrap: true)` inside another scroll view is a common anti-pattern in this codebase, causing O(N) layout passes. Also found indefinite animation delays (`20 * index`) which can lead to bad UX on long lists.
**Action:** Always prefer `CustomScrollView` with `SliverList` for nested lists, and verify animation delays are capped.
