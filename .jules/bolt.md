## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2026-08-20 - [Performance] Collection Iteration Optimization
**Learning:** Found multiple instances where `.where().map().toList()` and `.asMap().entries.map().toList()` chains were used. These methods allocate intermediate iterables, closures, and MapEntries which increases garbage collection overhead and cpu cycles.
**Action:** Replace functional chaining (`.where().map().toList()`) with direct collection comprehensions (`[for ... if ...]`) or traditional loops to construct collections in a single pass without intermediate allocations.
