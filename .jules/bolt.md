## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.

## 2026-07-10 - Iterable Chaining in Background Sync
**Learning:** The Dart core library `Iterable` methods like `.where()`, `.map()`, and `.toList()` create multiple intermediate object allocations. In highly frequent processes like background sync operations in repositories (e.g., `GroupsRepositoryImpl`), this object churn generates noticeable GC pressure.
**Action:** Use native Dart list comprehensions (`[for (final item in list) if (condition) item.id]`) for simple filtering and mapping. This evaluates the logic directly and builds the list in a single pass without intermediate iterable instances.
