## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2026-08-31 - [Dart Collections]
**Learning:** Using chained methods like `.where(...).map(...).toList()` or `.map(...).toList()` results in intermediate object allocations (like `MappedListIterable`), which increases Garbage Collection (GC) pressure significantly on large collections. This creates unexpected latency inside the Dart engine.
**Action:** Always prefer inline list comprehensions (`[for (final x in items) if (...) x]`) in Dart over chained iteration methods when generating lists to eliminate intermediate allocations and boost iteration performance.
