import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/widgets/demo_indicator_widget.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

class FakeSettingsState extends Fake implements SettingsState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSettingsEvent());
    registerFallbackValue(FakeSettingsState());
  });

  testWidgets('shows confirmation before exiting demo mode', (tester) async {
    final bloc = MockSettingsBloc();
    when(() => bloc.state).thenReturn(const SettingsState(isInDemoMode: true));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: bloc,
          child: const Scaffold(body: DemoIndicatorWidget()),
        ),
      ),
    );

    await tester.tap(find.text('Exit Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Exit Demo Mode?'), findsOneWidget);

    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ExitDemoMode())).called(1);
  });
}
