import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/pump_app.dart';

// Create a Fake that is a real Widget so it can be mounted
class FakeStatefulNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  final int _currentIndex;

  const FakeStatefulNavigationShell({
    super.key,
    required int currentIndex,
  }) : _currentIndex = currentIndex;

  @override
  int get currentIndex => _currentIndex;

  @override
  State<FakeStatefulNavigationShell> createState() =>
      _FakeStatefulNavigationShellState();

  @override
  void goBranch(int index, {bool? initialLocation}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _FakeStatefulNavigationShellState
    extends State<FakeStatefulNavigationShell> {
  @override
  Widget build(BuildContext context) {
    return Container(key: const Key('fake_shell_content'));
  }
}

void main() {
  testWidgets('FAB tooltip changes based on tab index', (tester) async {
    // 1. Dashboard (Index 0)
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const MainShell(
        navigationShell: FakeStatefulNavigationShell(currentIndex: 0),
      ),
      settingsState: const SettingsState(), // Defaults to demo mode off
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .tooltip,
      'Add Transaction',
    );

    // 2. Transactions (Index 1)
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const MainShell(
        navigationShell: FakeStatefulNavigationShell(currentIndex: 1),
      ),
      settingsState: const SettingsState(),
    );
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .tooltip,
      'Add Transaction',
    );

    // 3. Plan (Index 2) - Should NOT have FAB
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const MainShell(
        navigationShell: FakeStatefulNavigationShell(currentIndex: 2),
      ),
      settingsState: const SettingsState(),
    );
    expect(find.byType(FloatingActionButton), findsNothing);

    // 4. Accounts (Index 3)
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const MainShell(
        navigationShell: FakeStatefulNavigationShell(currentIndex: 3),
      ),
      settingsState: const SettingsState(),
    );
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .tooltip,
      'Add Account',
    );

    // 5. Recurring (Index 4)
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const MainShell(
        navigationShell: FakeStatefulNavigationShell(currentIndex: 4),
      ),
      settingsState: const SettingsState(),
    );
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .tooltip,
      'Add Recurring',
    );
  });
}
