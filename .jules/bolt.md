## 2024-05-24 - [Avoid `findChildIndexCallback` precomputation in `build()`]
**Learning:** Do not precompute a full ID-to-index Map inside `build()` for `ListView.builder`'s `findChildIndexCallback`, as iterating all items on every render negates the O(V) lazy rendering benefit and causes a performance regression.
**Action:** Instead, convert the widget to a `StatefulWidget` and cache the map in `initState` and `didUpdateWidget`.
## 2026-06-18 - [Hoist loop-invariant string operations]
**Learning:** Avoid calling operations like `.toLowerCase()` or `.trim()` inside iteration methods like `List.any()`. Hoisting them to variables outside the loop prevents redundant (N)$ string allocations and garbage collection pressure in Dart.
**Learning 2:** In Dart, getter accesses and simple null-coalescing (e.g., `targetDate ?? defaultDate`) are exceptionally fast. Do not attempt a Schwartzian transform (allocating Records or temporary Lists) to pre-compute these for `.sort()`, as the memory allocation overhead and GC pressure create a severe pessimization. Prefer in-place `.sort()` for simple property accesses.
**Action:** When inspecting iteration loops, always check if expressions evaluated inside the loop depend only on variables external to the loop, and hoist them out.
