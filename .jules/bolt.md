## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.

## 2024-05-23 - Avoid Chained Iterable Methods for Simple Filtering/Mapping
**Learning:** Chaining methods like `.where(...).map(...).toList()` or `.where(...).toList()` on Dart Iterables creates intermediate collections and closures, which significantly increases memory allocations and Garbage Collection (GC) pressure, especially when run frequently (e.g., in `build()` methods or during bloc state updates for large lists).
**Action:** Replace these chains with Dart list comprehensions (`[for (final item in list) if (condition) transform(item)]`). This iterates the collection exactly once, evaluating conditions and mapping values directly into the final list, which is highly optimized by the Dart compiler.
