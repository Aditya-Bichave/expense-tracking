## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2024-05-18 - Replacing chained Iterable mapping with List Comprehensions
**Learning:** Chaining `.where()` and `.map()` then `.toList()` creates intermediate lazy iterables that put pressure on the Garbage Collector, particularly when ran repetitively within State UI builders, Data Source retrievals, and BLoC emission streams in Dart.
**Action:** Replace `.where((x) => cond).map((x) => map).toList()` with collection comprehensions `[for (final x in list) if (cond) map]` for higher efficiency in single pass and deterministic Memory/CPU impact.
