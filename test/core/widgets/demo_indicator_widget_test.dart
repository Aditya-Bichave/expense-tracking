import 'package:expense_tracker/core/widgets/demo_indicator_widget.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('DemoIndicatorWidget', () {
    testWidgets('is visible when isInDemoMode is true', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(isInDemoMode: true),
        widget: const DemoIndicatorWidget(),
      );

      // ASSERT
      expect(find.text('Demo Mode Active'), findsOneWidget);
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 1.0);
    });

    testWidgets('is not visible when isInDemoMode is false', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(isInDemoMode: false),
        widget: const DemoIndicatorWidget(),
      );

      // ASSERT
      // The child is a SizedBox.shrink, so the text won't be in the tree
      expect(find.text('Demo Mode Active'), findsNothing);
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.0);
    });

    testWidgets(
      'tapping "Exit Demo" shows dialog and adds event on confirmation',
      (tester) async {
        // ARRANGE
        // We need to get the mock bloc from the provider tree to verify events
        late SettingsBloc mockSettingsBloc;
        await pumpWidgetWithProviders(
          tester: tester,
          settingsState: const SettingsState(isInDemoMode: true),
          widget: Builder(
            builder: (context) {
              // This is a bit of a hack to get the instance of the mock bloc created by the helper
              mockSettingsBloc = context.read<SettingsBloc>();
              return const DemoIndicatorWidget();
            },
          ),
        );

        // ACT - Tap the exit button
        expect(
          find.byKey(const ValueKey('button_demoIndicator_exit')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('button_demoIndicator_exit')),
        );
        await tester.pumpAndSettle(); // Let the dialog appear

        // ASSERT - Dialog is visible
        expect(find.text('Exit Demo Mode?'), findsOneWidget);

        // ACT - Tap the confirmation button in the dialog
        await tester.tap(find.text('Exit'));
        await tester.pump();

        // ASSERT - Event was added to the bloc
        verify(() => mockSettingsBloc.add(const ExitDemoMode())).called(1);
      },
    );
  });
}
