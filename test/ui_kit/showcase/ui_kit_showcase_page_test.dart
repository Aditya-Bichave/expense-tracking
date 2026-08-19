import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_checkbox.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_segmented_control.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_switch.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/showcase/ui_kit_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// The showcase page instantiates every component in the design system, so it
/// doubles as an integration check: a component whose constructor or theming
/// contract breaks fails here before it reaches a feature screen.
void main() {
  Future<void> pumpShowcase(WidgetTester tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const UiKitShowcasePage(),
      settle: false,
    );
    await tester.pump();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets('renders without throwing and shows its title', (tester) async {
    await pumpShowcase(tester);

    expect(find.byType(UiKitShowcasePage), findsOneWidget);
    expect(find.text('UI Kit Showcase'), findsOneWidget);
  });

  testWidgets('renders the typography scale', (tester) async {
    await pumpShowcase(tester);

    expect(find.text('Display Large'), findsOneWidget);
    expect(find.text('Body Regular'), findsOneWidget);
    expect(find.text('OVERLINE TEXT'), findsOneWidget);
    expect(find.byType(AppText), findsWidgets);
  });

  testWidgets('renders every button variant', (tester) async {
    await pumpShowcase(tester);

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Destructive'), findsOneWidget);
    expect(find.byType(AppButton), findsWidgets);
  });

  testWidgets('the switch reflects the toggle it is given', (tester) async {
    await pumpShowcase(tester);

    final toggle = find.byType(AppSwitch).first;
    await scrollTo(tester, toggle);

    expect(tester.widget<AppSwitch>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pump();

    expect(
      tester.widget<AppSwitch>(find.byType(AppSwitch).first).value,
      isTrue,
    );
  });

  testWidgets('the checkbox flips when tapped', (tester) async {
    await pumpShowcase(tester);

    final checkbox = find.byType(AppCheckbox).first;
    await scrollTo(tester, checkbox);

    expect(tester.widget<AppCheckbox>(checkbox).value, isFalse);

    await tester.tap(checkbox);
    await tester.pump();

    expect(
      tester.widget<AppCheckbox>(find.byType(AppCheckbox).first).value,
      isTrue,
    );
  });

  testWidgets('the segmented control starts on the first segment', (
    tester,
  ) async {
    await pumpShowcase(tester);

    // AppSegmentedControl is generic, so byType would only match
    // AppSegmentedControl<dynamic>; match on the raw type instead.
    final control = find
        .byWidgetPredicate((w) => w is AppSegmentedControl)
        .first;
    await scrollTo(tester, control);

    final widget = tester.widget(control) as AppSegmentedControl;
    expect(widget.groupValue, 0);
    expect(widget.children, isNotEmpty);
  });

  testWidgets('scrolling to the bottom builds every remaining section', (
    tester,
  ) async {
    await pumpShowcase(tester);

    final scrollable = find.byType(Scrollable).first;
    // Drive the whole page through a build so any component that throws on
    // layout surfaces here.
    for (var i = 0; i < 25; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
