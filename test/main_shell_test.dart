import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/pump_app.dart';

class MockStatefulNavigationShell extends Mock
    implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockStatefulNavigationShell mockShell;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockShell = MockStatefulNavigationShell();
    mockSettingsBloc = MockSettingsBloc();

    when(() => mockShell.currentIndex).thenReturn(0);
    when(
      () => mockShell.goBranch(
        any(),
        initialLocation: any(named: 'initialLocation'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
  });

  testWidgets('MainShell renders BottomNavigationBar', (tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: MainShell(navigationShell: mockShell),
      blocProviders: [
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
      ],
      settle: false,
    );
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
