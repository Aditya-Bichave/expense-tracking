# E2E Flow Inventory

The catalogue of user-facing journeys in this app, what covers each, and what is
still open. A "flow" here means a sequence a real user performs across more than
one screen or bloc — not a single page render.

Two layers cover flows, and they are not interchangeable:

| Layer | Location | Runs under | Counts toward Dart coverage |
| :--- | :--- | :--- | :--- |
| **Dart flow tests** | `test/integration/*_flow_test.dart` | `flutter test` | **Yes** |
| **Playwright smoke** | `ci/e2e/tests/*.spec.js` | real web build | No |

Dart flow tests are the primary layer: they exercise real blocs over mocked
repositories, so they catch wiring bugs *and* pay for themselves in coverage.
Playwright is a thin outer smoke check against a built artifact.

Flow test conventions are in [TEST_AUTHORING_SPEC](TEST_AUTHORING_SPEC.md) §7.

---

## A. Onboarding & identity

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| A1 | First launch → initial setup → dashboard | `/setup` → `/dashboard` | open |
| A2 | Email login → OTP verify → dashboard | `login_page` → `verify_otp_page` → dashboard | open |
| A3 | Login failure → error surfaced → retry | `login_page` | open |
| A4 | Profile setup after first sign-in | `profile_setup_page` → dashboard | open |
| A5 | App lock → biometric/PIN → unlock | `lock_screen` | open |
| A6 | Sign out → returns to login, state cleared | `settings_page` → `login_page` | open |
| A7 | Deep link / magic-link callback resolves to the right route | `/login-callback` | partial (`router_redirect_test.dart`) |

## B. Transactions (the core loop)

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| B1 | Add expense → appears in list → totals update | add/edit txn → txn list → dashboard | partial (`expense_creation_flow_test.dart`) |
| B2 | Add income → balance and dashboard reflect it | add/edit txn → dashboard | open |
| B3 | Edit an existing transaction → list reflects the edit | txn detail → add/edit → list | open |
| B4 | Delete a transaction → removed, totals recomputed | txn detail → list | open |
| B5 | Add-expense wizard, full multi-step path | `add_expense_wizard_page` | open |
| B6 | Wizard back-navigation preserves entered data | `add_expense_wizard_page` | open |
| B7 | Filter + sort the transaction list | `transaction_list_page` | open |
| B8 | Validation: empty amount, zero, negative, missing category | add/edit txn | open |

## C. Accounts

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| C1 | Create asset account → appears in list | add/edit account → account list | covered (`accounts_flow_test.dart`) |
| C2 | Create liability account → balance sign handled | add/edit account → list | open |
| C3 | Edit account → transactions re-associate correctly | add/edit account | partial (`accounts_flow_test.dart` covers the edit round-trip) |
| C4 | Delete account with existing transactions → guarded | account list | open |

## D. Budgets & categories

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| D1 | Create budget → detail shows spend vs limit | add/edit budget → budget detail | partial (`budgets_flow_test.dart` covers create) |
| D2 | Spend against a budget → progress/over-budget state | txn add → budget detail | open |
| D3 | Edit budget period → recalculated window | add/edit budget | partial (`budgets_flow_test.dart` covers the edit round-trip) |
| D4 | Create custom category → selectable in txn entry | add/edit category → add txn | open |
| D5 | Rename/recolour category → propagates to list and reports | category management | open |
| D6 | Delete category → transactions fall back to uncategorized | category management | open |

## E. Goals

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| E1 | Create goal → appears with 0% progress | add/edit goal → goals tab | covered (`goals_flow_test.dart`) |
| E2 | Log a contribution → progress advances | goal detail | open |
| E3 | Contribution completes the goal → achieved state | goal detail | open |
| E4 | Edit target amount → progress recomputed | add/edit goal | partial (`goals_flow_test.dart` covers the edit round-trip) |
| E5 | Delete goal → contributions handled | goal detail | open |

## F. Groups & splitting

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| F1 | Create group → appears in group list | `create_group_page` → `group_list_page` | covered (`groups_flow_test.dart`) |
| F2 | Edit group metadata | `create_group_page` (edit mode) | partial |
| F3 | Invite a member → invite artifact generated | group detail → invite sheet | partial (`invite_generation_sheet_test.dart`) |
| F4 | Add a group expense with equal split | `add_group_expense_page` → group detail | partial (`split_management_flow_test.dart`) |
| F5 | Unequal / percentage / share split | `add_group_expense_page` | open |
| F6 | Balances recomputed after a group expense | group detail | open |
| F7 | Settle up between two members | settlements | open |
| F8 | Leave / remove member → balances guarded | group detail | open |

## G. Recurring transactions

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| G1 | Create recurring rule → listed with next-due date | add/edit rule → rule list | open |
| G2 | Rule fires → generates a transaction | rule list → txn list | open |
| G3 | Pause / resume a rule | rule list | open |
| G4 | Edit cadence → next-due recomputed | add/edit rule | open |
| G5 | Delete rule → future occurrences stop | rule list | open |

## H. Reports

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| H1 | Spending by category, with date-range change | `spending_by_category_page` | open |
| H2 | Spending over time, granularity switch | `spending_over_time_page` | open |
| H3 | Income vs expense comparison | `income_vs_expense_page` | open |
| H4 | Budget performance report | `budget_performance_page` | open |
| H5 | Goal progress report | `goal_progress_page` | open |
| H6 | Empty-data state for every report | report shell | open |

## I. Settings, data & sync

| # | Flow | Screens | Status |
| :--- | :--- | :--- | :--- |
| I1 | Change theme / UI mode / palette → applied app-wide | `settings_page` | open |
| I2 | Change currency → amounts reformat | `settings_page` | open |
| I3 | Export data (CSV / PDF) | settings export | open |
| I4 | Import / restore backup | settings | open |
| I5 | Offline write → queued in outbox → syncs on reconnect | core/sync | open |
| I6 | Sync conflict resolution | core/sync | open |

---

## Coverage added in the 2026-08-19 pass

Three Dart flow tests were added, each driving real blocs over mocked
repositories and asserting the terminal side effect:

| File | Flows | Cases |
| :--- | :--- | ---: |
| `test/integration/goals_flow_test.dart` | E1, E4, plus list load/error/reset and data-change fan-in | 10 |
| `test/integration/accounts_flow_test.dart` | C1, C3, plus form validation and save-failure paths | 6 |
| `test/integration/budgets_flow_test.dart` | D1, D3, plus form validation, abandon, and list error | 8 |

Each file follows the same shape: a minimal `GoRouter` with only the routes the
flow needs, the real feature bloc registered in `GetIt`, mocked use cases, and a
`verify()` on the use case capturing exactly what the user typed.

Two determinism notes worth carrying into the next flow test:

- When an event is dispatched to a bloc **from outside the widget tree**, a
  single `pumpAndSettle()` returns before the emitted state reaches the frame.
  Wrap the dispatch in `tester.runAsync` and await a condition on
  `bloc.stream` — never a fixed delay. See `pumpFlow` in `goals_flow_test.dart`.
- Submit buttons at the bottom of a scroll view need `tester.ensureVisible`
  first. A plain `tap()` on an off-screen widget **warns and silently misses**
  rather than failing, which reads as "the handler never ran".

## How to use this file

1. Pick an `open` row from the highest-traffic section you have budget for
   (B and D are the core loop; A is the gate everything else sits behind).
2. Write the flow test per [TEST_AUTHORING_SPEC](TEST_AUTHORING_SPEC.md) §7.
3. Flip the row to `covered` and name the test file in the Status cell.

`partial` means a test exists that touches the flow but does not assert the
terminal side effect, or covers only the happy path. Those are worth upgrading
before writing something new — the setup cost is already paid.
