// ignore_for_file: directives_ordering

import 'package:expense_tracker/core/widgets/demo_indicator_widget.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'
    hide ValueGetter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockSettingsBloc extends Mock implements SettingsBloc {}

class FakeSettingsState extends Fake implements SettingsState {
  @override
  final bool isInDemoMode;
  FakeSettingsState({this.isInDemoMode = false});
}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUpAll(() {
    registerFallbackValue(FakeSettingsState());
  });

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<SettingsBloc>.value(
          value: mockSettingsBloc,
          child: const DemoIndicatorWidget(),
        ),
      ),
    );
  }

  group('DemoIndicatorWidget', () {
    testWidgets('is visible when isInDemoMode is true', (tester) async {
      when(
        () => mockSettingsBloc.state,
      ).thenReturn(FakeSettingsState(isInDemoMode: true));
      when(
        () => mockSettingsBloc.stream,
      ).thenAnswer((_) => Stream.value(FakeSettingsState(isInDemoMode: true)));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Demo Mode Active'), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('is not visible when isInDemoMode is false', (tester) async {
      when(
        () => mockSettingsBloc.state,
      ).thenReturn(FakeSettingsState(isInDemoMode: false));
      when(
        () => mockSettingsBloc.stream,
      ).thenAnswer((_) => Stream.value(FakeSettingsState(isInDemoMode: false)));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
      expect(find.text('Demo Mode Active'), findsNothing);
    });

    testWidgets(
      'tapping "Exit Demo" shows dialog and adds event on confirmation',
      (tester) async {
        when(
          () => mockSettingsBloc.state,
        ).thenReturn(FakeSettingsState(isInDemoMode: true));
        when(() => mockSettingsBloc.stream).thenAnswer(
          (_) => Stream.value(FakeSettingsState(isInDemoMode: true)),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Exit Demo'));
        await tester.pumpAndSettle();

        expect(find.text('Exit Demo Mode?'), findsOneWidget);

        await tester.tap(find.text('Exit'));
        await tester.pumpAndSettle();

        verify(() => mockSettingsBloc.add(const ExitDemoMode())).called(1);
      },
    );
  });
}
