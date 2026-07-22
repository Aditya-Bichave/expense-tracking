## Phase 1: Deep Audit & Issues Selection
Here is a list of 10 issues across the codebase that I have selected for implementation, prioritizing error/bug fixes and high-value non-feature enhancements based on memory constraints.

1. **Issue 1**: Missing timeout and try-catch block for `stream.firstWhere` in `lib/features/reports/presentation/widgets/report_filter_controls.dart`.
   - *Reasoning*: Awaiting stream without timeout/try-catch can cause the UI to hang forever if the expected state is never emitted.
2. **Issue 2**: Missing timeout and try-catch block for `stream.firstWhere` in `lib/features/accounts/presentation/pages/account_list_page.dart`.
   - *Reasoning*: Can cause refresh indicator to spin forever.
3. **Issue 3**: Missing timeout and try-catch block for `stream.firstWhere` in `lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart`.
   - *Reasoning*: Can cause refresh indicator to spin forever.
4. **Issue 4**: Missing timeout and try-catch block for `stream.firstWhere` in `lib/features/accounts/presentation/pages/accounts_tab_page.dart`.
   - *Reasoning*: Can cause refresh indicator to spin forever.
5. **Issue 5**: Refactor `.where().map()` to `[for... if...]` in `lib/features/goals/data/repositories/goal_repository_impl.dart`.
   - *Reasoning*: Directly improves performance by reducing O(N) object allocations and GC pressure.
6. **Issue 6**: Replace generic `List<dynamic>` with `List<GoalProgressData>` in `_previousProgressData` inside `lib/features/reports/presentation/pages/goal_progress_page.dart`.
   - *Reasoning*: Fixes type safety and adheres to the memory constraint to explicitly declare types for cached state arrays.
7. **Issue 7**: Fix `List<dynamic>` parsing for `members` in `lib/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart`.
   - *Reasoning*: Maintain sound type safety.
8. **Issue 8**: Unawaited background process not wrapped in try-catch in `lib/core/sync/sync_service.dart`.
   - *Reasoning*: Prevents silent background crashes.
9. **Issue 9**: Unawaited background process not wrapped in try-catch in `lib/features/groups/data/repositories/groups_repository_impl.dart`.
   - *Reasoning*: Prevents silent background crashes.
10. **Issue 10**: Implement a `try-catch` block around the unawaited call in `lib/core/auth/session_cubit.dart`'s `_init` method.
    - *Reasoning*: Ensure proper error handling.
