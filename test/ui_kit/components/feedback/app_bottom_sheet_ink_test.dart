import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// Regression: `AppBottomSheet` paints its own background and is shown on a
/// transparent modal route, so without a `Material` of its own the `ListTile`s
/// inside it drew their ink splash and selected-tile colour onto a Material
/// sitting *behind* that background — invisible to the user. Newer Flutter
/// asserts on exactly this arrangement, which is how it surfaced.
void main() {
  testWidgets('provides a Material ancestor in front of its background', (
    tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const AppBottomSheet(
        title: 'Pick one',
        child: AppListTile(title: Text('Row')),
      ),
    );

    final tile = find.byType(ListTile);
    expect(tile, findsOneWidget);

    // Walk up from the tile collecting ancestors in order. A Material must be
    // reached before the decorated Container that paints the sheet background.
    final ancestors = <Widget>[];
    tester.element(tile).visitAncestorElements((element) {
      ancestors.add(element.widget);
      return true;
    });

    final materialIndex = ancestors.indexWhere((w) => w is Material);
    final decorationIndex = ancestors.indexWhere(
      (w) => w is Container && w.decoration is BoxDecoration,
    );

    expect(materialIndex, isNot(-1), reason: 'no Material ancestor at all');
    expect(decorationIndex, isNot(-1), reason: 'sheet background not found');
    expect(
      materialIndex,
      lessThan(decorationIndex),
      reason:
          'the Material must sit in front of the painted background, '
          'otherwise ink and selected-tile colours are hidden by it',
    );
  });

  testWidgets('renders its title and child without raising an assertion', (
    tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const AppBottomSheet(
        title: 'Choose a split',
        child: Column(
          children: [
            AppListTile(title: Text('Equally')),
            AppListTile(title: Text('Exact amounts')),
          ],
        ),
      ),
    );

    expect(find.text('Choose a split'), findsOneWidget);
    expect(find.text('Equally'), findsOneWidget);
    expect(find.text('Exact amounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tile inside the sheet still reports its tap', (tester) async {
    var taps = 0;

    await pumpWidgetWithProviders(
      tester: tester,
      widget: AppBottomSheet(
        child: AppListTile(title: const Text('Tap me'), onTap: () => taps++),
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('a sheet without a title omits the header and divider', (
    tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const AppBottomSheet(child: Text('Body only')),
    );

    expect(find.text('Body only'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });
}
