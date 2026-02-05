import 'package:expense_tracker/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/pump_app.dart';

// Fake implementation of StatefulNavigationShell
// It must be a StatefulWidget to match the expected type in the widget tree
class FakeStatefulNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  final int index;

  const FakeStatefulNavigationShell({
    super.key,
    this.index = 0,
  });

  @override
  int get currentIndex => index;

  @override
  void goBranch(int index, {bool? initialLocation}) {}

  @override
  State<FakeStatefulNavigationShell> createState() =>
      _FakeStatefulNavigationShellState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStatefulNavigationShellState
    extends State<FakeStatefulNavigationShell> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeStatefulNavigationShell());
  });

  group('MainShell', () {
    testWidgets(
        'renders FAB with "Add Transaction" tooltip for Dashboard (index 0)',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const MainShell(
          navigationShell: FakeStatefulNavigationShell(index: 0),
        ),
      );

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final tooltipFinder = find.byTooltip('Add Transaction');
      expect(tooltipFinder, findsOneWidget);
    });

    testWidgets(
        'renders FAB with "Add Transaction" tooltip for Transactions (index 1)',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const MainShell(
          navigationShell: FakeStatefulNavigationShell(index: 1),
        ),
      );

      expect(find.byTooltip('Add Transaction'), findsOneWidget);
    });

    testWidgets('renders FAB with "Add Account" tooltip for Accounts (index 3)',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const MainShell(
          navigationShell: FakeStatefulNavigationShell(index: 3),
        ),
      );

      expect(find.byTooltip('Add Account'), findsOneWidget);
    });

    testWidgets(
        'renders FAB with "Add Recurring Transaction" tooltip for Recurring (index 4)',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const MainShell(
          navigationShell: FakeStatefulNavigationShell(index: 4),
        ),
      );

      expect(find.byTooltip('Add Recurring Transaction'), findsOneWidget);
    });

    testWidgets('does not render FAB for Settings (index 5)', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const MainShell(
          navigationShell: FakeStatefulNavigationShell(index: 5),
        ),
      );

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
