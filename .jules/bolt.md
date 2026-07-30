## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.

## 2026-07-30 - [Performance] Refactoring inefficient collection pipelines
**Learning:** Dart's `.where(...).map(...).toList()` chains create temporary iterable instances for every step, causing significant O(N) memory allocations and unnecessary garbage collection overhead when filtering large local storage queries.
**Action:** Always replace chained `.where().map().toList()` and related patterns with single-pass Dart collection comprehensions (e.g. `[for (var x in list) if (condition) transform(x)]`) or standard `for` loops in performance-sensitive areas like repository reads or build methods.
