## 2026-01-23 - Flutter List Optimization via State Hoisting
**Learning:** Accessing Blocs or Providers inside individual list items (e.g., `context.watch<Bloc>()`) causes O(N) listeners and rebuilds. Hoisting the state access to the parent widget (Page or ListView) and passing simple data down reduces this to O(1) listener and significantly improves scrolling performance.
**Action:** When reviewing or writing list widgets, always check if children are listening to Blocs. If they are, refactor to pass data down from the parent.
