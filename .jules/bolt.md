## 2026-01-20 - Loop Invariant Hoisting in Hive Datasources
**Learning:** Simple operations like `DateTime` creation or `String.split` become expensive bottlenecks when executed inside tight loops over large datasets (like Hive boxes). Hoisting these invariants outside the loop significantly reduces object allocation.
**Action:** Always inspect loops in data sources (`getExpenses`, `getIncomes`) for constant expressions that can be calculated once beforehand. Use `Set` for inclusion checks instead of `List` when filtering.
