import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/pump_app.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
  });

  testWidgets('AppearanceSettingsSection renders correctly and interactions work', (
    WidgetTester tester,
  ) async {
    // pumpWidgetWithProviders handles mockSettingsBloc internally via settingsState param
    // OR we can override it by passing it in blocProviders list?
    // Looking at pump_app.dart:
    // It creates its own MockSettingsBloc unless we can inject one.
    // It takes `SettingsState? settingsState`.
    // It DOES NOT take a `SettingsBloc`.

    // So to verify interactions on SettingsBloc, I need to pass my mock in `blocProviders`
    // BUT pumpWidgetWithProviders adds its own SettingsBloc provider FIRST in the list.
    // Wait, `MultiBlocProvider` providers list order matters?
    // If I add another SettingsBloc provider in `blocProviders`, it will be DOWNSTREAM or UPSTREAM?
    // `MultiBlocProvider` merges them. Duplicates might throw or last one wins?

    // Actually, `pumpWidgetWithProviders` instantiates `mockSettingsBloc` inside.
    // It does NOT expose it. So I cannot verify calls on it unless I refactor `pumpWidgetWithProviders` or don't use it.

    // I will construct the test manually without `pumpWidgetWithProviders` to control the Bloc.

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

    await tester.pumpWidget(
      BlocProvider<SettingsBloc>.value(
        value: mockSettingsBloc,
        child: MaterialApp(
          home: Scaffold(
            body: AppearanceSettingsSection(
              state: SettingsState(),
              isLoading: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AppListTile), findsNWidgets(3));
    expect(find.text('UI Mode'), findsOneWidget);
    expect(find.text('Palette / Variant'), findsOneWidget);
    expect(find.text('Brightness Mode'), findsOneWidget);

    // Open UI Mode dropdown (PopupMenuButton)
    await tester.tap(find.byTooltip('Select UI Mode'));
    await tester.pumpAndSettle();

    // Select Quantum mode
    await tester.tap(find.text('Quantum').last);
    await tester.pumpAndSettle();

    verify(
      () => mockSettingsBloc.add(const UpdateUIMode(UIMode.quantum)),
    ).called(1);

    // Open Brightness Mode dropdown
    await tester.tap(find.byTooltip('Select Brightness Mode'));
    await tester.pumpAndSettle();

    // Select Dark mode
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    verify(
      () => mockSettingsBloc.add(const UpdateTheme(ThemeMode.dark)),
    ).called(1);
  });
}
