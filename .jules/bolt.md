## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.

## 2024-05-27 - [Avoid chained iterables .where().map().toList()]
**Learning:** Chaining `.where(...).map(...).toList()` methods creates intermediate iterables and closures, causing GC pressure, particularly noticeable when doing this inside UI build methods or when loading data from data sources.
**Action:** Use direct Dart list comprehensions `[for (var item in list) if (condition) transform(item)]` to allocate the list once and avoid intermediate wrappers.
