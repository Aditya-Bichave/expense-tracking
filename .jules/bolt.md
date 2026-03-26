
## 2026-03-26 - Precomputing Maps inside build() negates ListView.builder lazy rendering
**Learning:** For lazy list performance (`ListView.builder`), using `findChildIndexCallback` with a map tracking IDs to indices transforms key lookup from O(V) (where V is the length of visible items) to O(1). However, calculating that ID-to-index map entirely inside the `build()` method executes an O(N) loop on every single render. When N is large, this completely neutralizes the performance benefit of lazy list rendering, causing severe frame drops.
**Action:** Always precompute state-derived mappings in `initState` and `didUpdateWidget` (inside a `StatefulWidget` or using a bloc state) rather than inside `build()`. Make sure `didUpdateWidget` checks for reference equality of the underlying list.
