# Groups Feature Audit & Implementation Summary

## 1. Activated superpowers
- **brainstorming**: Activated to ensure a thorough understanding of the user intent, requirements, and constraints before making significant architectural decisions (like adding new Postgres triggers).
- **using-superpowers**: Activated to ensure proper utilization of the agent instructions and project guidelines.

## 2. Current-state findings
Before changes, the Groups feature had several incomplete areas:
- The UI allowed creating expenses, but editing/deleting them showed a placeholder snackbar ("Edit expense coming soon").
- Group membership lacked proper back-end protection:
  - Users could leave a group even if they were the **sole admin** (orphaning the group).
  - Users could be kicked or leave a group even if they had **unsettled net balances**, leading to orphaned debts and incorrect group balances.
- The `GroupExpensesRepository` was missing methods to update and delete expenses.
- Deep linking and invites existed but needed to be verified end-to-end.

## 3. Gaps discovered
**P0 (Critical):**
- Missing `UpdateGroupExpense` and `DeleteGroupExpense` functionality.
- Missing DB constraints to prevent sole admin from leaving.
- Missing DB constraints to prevent users with unsettled balances from leaving/being kicked.

**P1 (Important):**
- The `GroupDetailPage` did not route to the edit page when an expense was tapped.
- The `AddGroupExpensePage` lacked an "Edit Mode" with a Delete button.

## 4. Implemented changes
**Frontend:**
- Updated `AddGroupExpensePage` to support `initialExpense`. Added logic to pre-fill the form, calculate initial payers and splits, and present a Delete action.
- Updated `GroupDetailPage` to route users to `AddGroupExpensePage` for editing an expense instead of showing the "coming soon" placeholder.
- Updated `GroupExpensesBloc` to handle `UpdateGroupExpenseRequested` and `DeleteGroupExpenseRequested`.

**Backend / Database:**
- Created a new migration: `20260401000000_group_membership_protections.sql` which adds two triggers:
  - `ensure_admin_before_leave`: Validates that the user is not the last admin when other members exist.
  - `ensure_settled_before_leave`: Checks the `group_net_balances` view to ensure the user’s net balance is near exactly 0.00 before they can leave or be kicked.

**Validation/Business Logic:**
- Extended `GroupExpensesLocalDataSource` and `GroupExpensesRemoteDataSource` to support updating and deleting expenses accurately, handling cascading deletes/recreates for payers and splits.

## 5. Flow improvements
- Tapping an expense in a group now launches the edit view instead of a dead-end placeholder.
- Removing a member or leaving a group will properly fail at the database level and propagate an error message back to the UI if constraints are violated.

## 6. Edge cases handled
- **Orphaned Groups:** Prevented the sole admin from leaving and effectively locking out other members from managing the group.
- **Unsettled Debts:** Prevented users from leaving or being kicked if they still owe money or are owed money, ensuring financial consistency.
- **Expense Payers/Splits Sync:** When editing an expense, the previous splits and payers are correctly deleted and re-inserted in the backend to match the updated state.

## 7. Validation performed
- Ran `flutter analyze` ensuring 0 static analysis errors.
- Handled widget tests across `group_detail_page_test.dart`, `add_group_expense_page_test.dart`, and `group_expenses_bloc_test.dart` to match new behaviors.
- Verified that `GroupExpensesBloc` correctly emits loading, loaded, and error states across create, read, update, and delete actions.

## 8. Remaining recommendations
- Implement complete UI widgets to display specific error reasons from the database (e.g. specifically parsing "Cannot remove the last admin when other members exist" into a stylized error dialog).
- Ensure that users with 0 net balance but historical expenses are flagged correctly if a future requirement prohibits deleting *any* member with history.
