## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2025-05-18 - [Optimizing List and Map Operations in Dart]
**Learning:** In Dart, chaining `.where().map().toList()` or similar methods on Iterables creates intermediate objects in memory for each step of the chain. For lists with many items, this can cause unnecessary GC pressure and slowdowns. Same applies to things like `Map.entries.map().toList()`.
**Action:** When filtering, transforming or aggregating Iterables, prefer direct List or Map comprehensions (e.g. `[for (var x in list) if (x.isValid) x.mapItem()]`) which execute in a single pass without allocating temporary iterables.
