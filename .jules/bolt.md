## 2024-06-25 - Prevent O(N) allocation on iterable transformations
**Learning:** Chaining `.where().map().toList()` and `.map().toList()` allocates temporary iterables and lists, contributing to garbage collection overhead in Flutter. Replacing these chains with Dart list comprehensions `[for (var item in list) if (condition) item]` creates the final list in a single pass without intermediate iterables.
**Action:** When transforming collections, use Dart list and set comprehensions (e.g. `[for (var e in list) e]`) rather than mapping methods that create intermediate iterables.

## 2024-06-25 - Prevent O(N) allocation on iterable transformations
**Learning:** Chaining `.where().map().toList()` and `.map().toList()` allocates temporary iterables and lists, contributing to garbage collection overhead in Flutter. Replacing these chains with Dart list comprehensions `[for (var item in list) if (condition) item]` creates the final list in a single pass without intermediate iterables.
**Action:** When transforming collections, use Dart list and set comprehensions (e.g. `[for (var e in list) e]`) rather than mapping methods that create intermediate iterables.

## 2024-06-25 - Prevent O(N) allocation on iterable transformations
**Learning:** Chaining `.where().map().toList()` and `.map().toList()` allocates temporary iterables and lists, contributing to garbage collection overhead in Flutter. Replacing these chains with Dart list comprehensions `[for (var item in list) if (condition) item]` creates the final list in a single pass without intermediate iterables.
**Action:** When transforming collections, use Dart list and set comprehensions (e.g. `[for (var e in list) e]`) rather than mapping methods that create intermediate iterables.

## 2024-06-25 - Prevent O(N) allocation on iterable transformations
**Learning:** Chaining `.where().map().toList()` and `.map().toList()` allocates temporary iterables and lists, contributing to garbage collection overhead in Flutter. Replacing these chains with Dart list comprehensions `[for (var item in list) if (condition) item]` creates the final list in a single pass without intermediate iterables.
**Action:** When transforming collections, use Dart list and set comprehensions (e.g. `[for (var e in list) e]`) rather than mapping methods that create intermediate iterables.
