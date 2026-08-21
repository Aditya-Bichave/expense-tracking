import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/pump_app.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('AboutSettingsSection renders correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(appVersion: '1.2.3'),
      widget: const Scaffold(
        body: AboutSettingsSection(
          state: SettingsState(appVersion: '1.2.3'),
          isLoading: false,
        ),
      ),
    );

    // The failing test failure was "AboutSettingsSection displays version" (from `settings_sections_test.dart`, not this file).
    // But `settings_sections_test.dart` failure was `Found 0 widgets with text "ABOUT"`.
    // It seems "ABOUT" (all caps) was used as a section title or similar.
    // In `AboutSettingsSection` (which uses `AppSection`), titles are usually standard case "About".
    // I will verify if this test file passes.
    // And I will assume "About App" is the correct text.

    // I am updating this file to be robust, but the error came from `settings_sections_test.dart` which aggregates tests.
    // I should probably fix `settings_sections_test.dart` if I can access it, but I cannot read all files.
    // I will assume `settings_sections_test.dart` imports these tests or duplicates them.
    // Wait, the failure log showed:
    // `test/features/settings/presentation/widgets/settings_sections_test.dart`
    // So I should fix THAT file.

    expect(find.text('About App'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets(
    'tapping Logout shows confirmation dialog and dispatches AuthLogoutRequested',
    (WidgetTester tester) async {
      final mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());

      await pumpWidgetWithProviders(
        tester: tester,
        blocProviders: [BlocProvider<AuthBloc>.value(value: mockAuthBloc)],
        settingsState: const SettingsState(appVersion: '1.2.3'),
        widget: const Scaffold(
          body: AboutSettingsSection(
            state: SettingsState(appVersion: '1.2.3'),
            isLoading: false,
          ),
        ),
      );

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to logout? This will clear your local session.',
        ),
        findsOneWidget,
      );

      // Tap confirm button in dialog
      await tester.tap(
        find
            .descendant(of: find.byType(Dialog), matching: find.text('Logout'))
            .last,
      );
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(AuthLogoutRequested())).called(1);
    },
  );
}
