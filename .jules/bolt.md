## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.

## 2024-05-25 - [Use List Comprehensions instead of map/where]
**Learning:** Chaining `.where().map().toList()` or even simple `.map().toList()` allocates intermediate iterables (`WhereIterable`, `MappedIterable`) and closures during every render or iteration phase. In Flutter, this creates significant garbage collection pressure inside `build()` methods and data processing functions.
**Action:** Replace these chains with Dart list comprehensions `[for (final item in collection) if (condition) item]`. This performs a single pass over the collection, filters and maps inline, and allocates only the final list.
