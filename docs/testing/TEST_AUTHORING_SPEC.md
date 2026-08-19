# Test Authoring Spec

Repo-specific conventions for writing tests in this project. This is the
reference an agent (or a human) reads instead of inferring conventions from a
sample of existing files — the existing suite is not internally consistent, so
inference produces drift.

## 1. Layout

| Path | Contains |
| :--- | :--- |
| `test/features/<feature>/**` | Mirrors `lib/features/<feature>/**` one-for-one. A test for `lib/features/goals/domain/usecases/add_goal.dart` lives at `test/features/goals/domain/usecases/add_goal_test.dart`. |
| `test/core/**` | Mirrors `lib/core/**`. |
| `test/integration/*_flow_test.dart` | Multi-bloc, multi-page user flows. See §7. |
| `test/golden/**` | Visual regression. Do not add to this without a human asking. |
| `test/helpers/**` | Shared harness. Extend rather than duplicate. |
| `ci/e2e/tests/*.spec.js` | Playwright, runs against a real web build. Separate stack; not part of the Dart coverage number. |

`test/flutter_test_config.dart` runs before every test in the tree. It seeds
`faker`, registers mocktail fallback values, and disables Google Fonts network
fetching. You never need to do those three things yourself.

## 2. The harness

`test/helpers/pump_app.dart` exposes `pumpWidgetWithProviders`. Use it for any
widget test that touches theming, localization, or navigation:

```dart
await pumpWidgetWithProviders(
  tester: tester,
  widget: const SomePage(),
  settingsState: const SettingsState(uiMode: UIMode.elemental),
  blocProviders: [BlocProvider<SomeBloc>.value(value: mockSomeBloc)],
);
```

It supplies `MaterialApp.router`, `AppLocalizations`, the theme built from
`SettingsState`, a mock `SettingsBloc`, and a mock `AccountListBloc`. Passing
`settle: false` skips `pumpAndSettle` — needed for pages with an indefinite
animation (shimmer, `confetti`, `flutter_animate` loops), which otherwise hang
the test until timeout.

Mocks live in `test/helpers/mock_helpers.dart` (feature repositories, blocs,
fallback values) and `test/helpers/core_mocks.dart` (Supabase, Hive, secure
storage, GoRouter). **Add new shared mocks there**, not inline, when more than
one test file needs them.

`registerXMocks(getIt)` helpers unregister-then-register, so they are safe to
call repeatedly across `setUp`.

## 3. Choosing the test type

| Production file archetype | Test type | Why |
| :--- | :--- | :--- |
| `domain/usecases/*.dart` | Pure unit | Thin; one call, one `Either` branch each way. Cheap lines. |
| `domain/entities/*.dart` with `copyWith`/computed getters | Pure unit | Branch-dense, zero setup. |
| `data/repositories/*_impl.dart` | Unit with mocked datasources | Highest line yield in this repo. Cover success, cache-hit, cache-miss, and each failure mapping. |
| `data/models/*.dart` (`fromJson`/`toJson`/`toEntity`) | Pure unit | Null-handling branches are where the real bugs are. |
| `presentation/bloc/*_bloc.dart` | `bloc_test` | Assert emitted state *sequence*, not just the final state. |
| `presentation/pages/*.dart` | Widget test via harness | Assert per-state rendering: loading, loaded, empty, error. |
| `presentation/widgets/*.dart` | Widget test | Only when it has conditional rendering or an interaction callback. |
| Multi-page journeys | Flow test in `test/integration/` | See §7. |

Do not write widget tests for purely decorative widgets. They inflate the
number without reducing risk, and they are the first thing to break on a theme
change.

## 4. Assertion bar

Every test must be able to fail for a reason that matters. Concretely, at least
one assertion per test must check one of:

- a returned value or `Either` branch
- an emitted bloc state's *fields*, not just its runtime type
- a `verify()` on a collaborator with matched arguments
- a rendered widget that only appears in one branch of the code under test
- a thrown exception's type **and** message/payload

Rejected patterns:

```dart
// No. Asserts nothing about behaviour.
test('creates bloc', () { expect(SomeBloc(repo), isNotNull); });

// No. Passes for every possible failure state.
expect(bloc.state, isA<SomeErrorState>());

// Yes.
expect(bloc.state, isA<SomeErrorState>()
  .having((s) => s.message, 'message', 'Network unreachable'));
```

For `bloc_test`, prefer `expect: () => [...]` with concrete state matchers over
`isA<T>()` alone, and add `verify:` when the interesting outcome is a side
effect rather than a state.

## 5. Determinism rules

These are the failure modes this codebase actually hits.

**Time.** `lib/core/services/system_clock.dart` exists — inject it. Never call
`DateTime.now()` in a test's expected value. For anything schedule-shaped
(recurring transactions, budget periods, goal deadlines) pin a fixed
`DateTime(2024, 1, 15)` and compute expectations from it by hand.

**Randomness.** `faker` is seeded from `FAKER_SEED` in `flutter_test_config.dart`.
If a test's outcome depends on faker output, it is already wrong — use literal
fixtures for anything asserted on. `Uuid` must be mocked when the generated id
appears in an assertion.

**Async.** Use `tester.pump(Duration)` with an explicit duration over bare
`pumpAndSettle` when a page has any looping animation. Never `await
Future.delayed` in a test body. For streams, use `emitsInOrder` rather than
collecting into a list and sleeping.

**Ordering.** No shared mutable top-level state between tests. If you need
`GetIt`, reset it in `tearDown` (`await getIt.reset()`), or the next file in the
run inherits your registrations. The suite runs with
`--test-randomize-ordering-seed=random` in CI, so order coupling *will* be
found — just not necessarily on your machine.

**Network.** No test may perform real I/O. Supabase, `http`, `connectivity_plus`,
and `share_plus` all have mocks or platform-channel stubs available; a test that
needs a new one adds it to `core_mocks.dart`.

**Platform channels.** For plugins without a mock
(`path_provider`, `package_info_plus`, `local_auth`, `permission_handler`), stub
with `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(...)`
in `setUp` and clear it in `tearDown`.

## 6. Fixing defects found by tests

When a new test fails and the production code is at fault:

1. Confirm it is a real defect, not a wrong expectation. Read the production
   code path before changing it.
2. Apply the **smallest** correct fix. Do not restructure surrounding code.
3. Keep the failing test as the regression test, and make sure it fails against
   the pre-fix code — if it passes either way, it is not a regression test.
4. Note it. Defect fixes are the highest-value output of a coverage run and the
   part nobody can reconstruct from the diff alone.

Never: widen an assertion, add `skip:`, wrap in `try/catch`, or change the test
to match buggy behaviour.

## 7. Flow tests

`test/integration/*_flow_test.dart` are widget tests that span pages. They are
not `integration_test` (no device, no `IntegrationTestWidgetsFlutterBinding`) —
they run under plain `flutter test` and *do* count toward line coverage, which
is why they are worth writing.

Shape:

- Build a `GoRouter` with only the routes the flow needs.
- Use **real** blocs over **mocked collaborators** — the use case where the
  feature has one, otherwise the repository. Mocking the bloc defeats the
  purpose; mocking its collaborator keeps the flow deterministic.
- Drive with `tester.tap` / `enterText` / `pumpAndSettle`, and assert on what the
  user would see at each step.
- Assert the terminal side effect via `verify()` on that same collaborator,
  capturing its arguments — that the flow actually carried the user's input all
  the way through is the point.

See `test/integration/groups_flow_test.dart` for the established pattern and
`E2E_FLOW_INVENTORY.md` for what still needs one.

## 8. Before you finish

```bash
flutter analyze
dart format .
flutter test
flutter test --test-randomize-ordering-seed=random
./ci/check_coverage.sh
```

`dart format` is enforced by CI and will fail the build on its own. `print` is
forbidden by the analyzer config; use `logging`. A `TODO` without a ticket id
fails the CI policy check.
