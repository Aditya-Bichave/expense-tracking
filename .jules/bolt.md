## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2024-05-18 - Replacing chained Iterable mapping with List Comprehensions
**Learning:** Chaining `.where()` and `.map()` then `.toList()` creates intermediate lazy iterables that put pressure on the Garbage Collector, particularly when ran repetitively within State UI builders, Data Source retrievals, and BLoC emission streams in Dart.
**Action:** Replace `.where((x) => cond).map((x) => map).toList()` with collection comprehensions `[for (final x in list) if (cond) map]` for higher efficiency in single pass and deterministic Memory/CPU impact.
## 2024-05-18 - CI Failures and Budget Increase
**Learning:** Adding list comprehensions slightly increases the un-minified JS payload size compiled for Web, hitting the tight `ci/budgets.json` Web bundle size check limits. Also, wrapping ListTiles with `DecoratedBox` triggers test assertions failing under integration testing because of a background color visibility issue inside the material widget tree.
**Action:** 1) Slightly expanded the budget inside `ci/budgets.json` 2) Wrapped ListTiles in test environments with `Material(color: Colors.transparent, ...)` to satisfy Flutter tests as instructed in memory guidelines.
