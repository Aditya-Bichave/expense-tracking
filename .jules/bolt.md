## 2026-07-23 - Optimizing Chained Iterables in Dart
**Learning:** Dart's collection methods like `.where()` and `.map()` create lazy iterables, but chaining them and terminating with `.toList()` forces the allocation of intermediate iterable objects and closures, causing unnecessary GC pressure and CPU cycles, particularly during widget builds or data source operations.
**Action:** Replace `list.where(...).map(...).toList()` (and similar chained patterns) with direct list comprehensions `[for (final item in list) if (condition) transform(item)]` to filter, transform, and collect the elements into a pre-allocated list in a single fast O(N) pass without creating intermediate iterables.

## 2026-07-23 - Optimizing Chained Iterables in Dart
**Learning:** Dart's collection methods like `.where()` and `.map()` create lazy iterables, but chaining them and terminating with `.toList()` forces the allocation of intermediate iterable objects and closures, causing unnecessary GC pressure and CPU cycles, particularly during widget builds or data source operations.
**Action:** Replace `list.where(...).map(...).toList()` (and similar chained patterns) with direct list comprehensions `[for (final item in list) if (condition) transform(item)]` to filter, transform, and collect the elements into a pre-allocated list in a single fast O(N) pass without creating intermediate iterables.
