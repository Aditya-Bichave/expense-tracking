import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/pages/about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    settingsBloc = MockSettingsBloc();
  });

  Future<void> pumpAbout(WidgetTester tester, SettingsState state) async {
    when(() => settingsBloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: const AboutPage(),
        ),
      ),
    );
  }

  testWidgets('shows the app name and the loaded version', (tester) async {
    await pumpAbout(
      tester,
      const SettingsState(
        packageInfoStatus: PackageInfoStatus.loaded,
        appVersion: '1.4.2+37',
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Version 1.4.2+37'), findsOneWidget);
  });

  testWidgets('reports the loading state rather than a blank version', (
    tester,
  ) async {
    await pumpAbout(
      tester,
      const SettingsState(packageInfoStatus: PackageInfoStatus.loading),
    );

    expect(find.text('Loading version...'), findsOneWidget);
  });

  testWidgets('surfaces a version load failure', (tester) async {
    await pumpAbout(
      tester,
      const SettingsState(
        packageInfoStatus: PackageInfoStatus.error,
        packageInfoError: 'Failed to load app version',
      ),
    );

    expect(find.text('Failed to load app version'), findsOneWidget);
  });

  testWidgets('offers the open source licence page', (tester) async {
    await pumpAbout(
      tester,
      const SettingsState(
        packageInfoStatus: PackageInfoStatus.loaded,
        appVersion: '1.0.0+1',
      ),
    );

    expect(find.text('Open source licences'), findsOneWidget);

    await tester.tap(find.text('Open source licences'));
    await tester.pumpAndSettle();

    // Flutter's built-in licence registry page.
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
