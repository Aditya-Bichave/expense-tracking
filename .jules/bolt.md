## 2026-08-05 - Avoid `.where().map().toList()` chains
**Learning:** Chaining methods like `.where(...).map(...).toList()` allocates intermediate iterables which can increase garbage collection (GC) pressure, particularly in build methods or loops that run frequently.
**Action:** Always prefer Dart list comprehensions (e.g., `[for (final item in list) if (condition) item.property]`) to filter and map data directly into a list, avoiding intermediate allocations.
