## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2024-05-24 - [Avoid chained Iterables during collection deletion]
**Learning:** Chaining `.where(...).map(...).toList()` on Hive `Box.values` (or any Iterable) creates multiple intermediate collections and closures, heavily contributing to memory allocation and garbage collection pressure, particularly on list-heavy operations like deleting relational data.
**Action:** Use single-pass Dart collection comprehensions like `[for (final x in list) if (condition) x.id]` instead of `list.where(condition).map((x) => x.id).toList()` to improve performance and avoid GC spikes.
