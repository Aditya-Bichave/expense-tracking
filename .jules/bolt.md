## 2026-08-07 - Precompute List of Categories as Set for O(1) lookup
**Learning:** Checking `.contains()` on a `List` inside of a loop or `.where()` introduces an O(N*M) time complexity trap.
**Action:** When filtering or counting based on containment, precompute the `List` into a `Set` prior to entering the loop for O(1) lookups, reducing time complexity to O(N+M).

## 2026-08-07 - Precompute List of Categories as Set for O(1) lookup
**Learning:** Checking `.contains()` on a `List` inside of a loop or `.where()` introduces an O(N*M) time complexity trap.
**Action:** When filtering or counting based on containment, precompute the `List` into a `Set` prior to entering the loop for O(1) lookups, reducing time complexity to O(N+M).
