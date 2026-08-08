## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2026-08-08 - [Optimize GC pressure by avoiding intermediate iterables]
**Learning:** Chaining `.where(...).toList()` or `.where(...).map(...).toList()` in Dart creates intermediate lazy iterables which are instantiated on every evaluation and pressure the garbage collector (GC), especially in build methods or list mappings.
**Action:** Replace such chains with Dart list comprehensions `[for (var item in list) if (condition) map(item)]` to allocate memory only once directly into the target list. This is particularly impactful when initializing forms, loading repositories, or rebuilding widgets.
