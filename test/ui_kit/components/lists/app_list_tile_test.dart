import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppListTile', () {
    testWidgets('renders title', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: ListView(
          children: [AppListTile(title: const Text('Title'), onTap: () {})],
        ),
      );
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: ListView(
          children: [
            AppListTile(
              title: const Text('Title'),
              subtitle: const Text('Subtitle'),
              onTap: () {},
            ),
          ],
        ),
      );
      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('renders leading and trailing widgets', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: ListView(
          children: [
            AppListTile(
              title: const Text('Title'),
              leading: const Icon(Icons.person),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      );
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool wasTapped = false;
      await pumpWidgetWithProviders(
        tester: tester,
        widget: ListView(
          children: [
            AppListTile(
              title: const Text('Title'),
              onTap: () => wasTapped = true,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });
}
