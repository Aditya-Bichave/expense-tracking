import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/data_management_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/general_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/legal_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/core_mocks.dart';
import '../../../../helpers/pump_app.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockDataManagementBloc
    extends MockBloc<DataManagementEvent, DataManagementState>
    implements DataManagementBloc {}

class _FakeSettingsEvent extends Fake implements SettingsEvent {}

class _FakeDataManagementEvent extends Fake implements DataManagementEvent {}

class _FakeAuthEvent extends Fake implements AuthEvent {}

/// A url_launcher platform that reports every launch attempt as refused, which
/// is what drives the "Could not launch" toast.
class _RefusingUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => false;
}

void main() {
  late MockSettingsBloc settingsBloc;
  late MockDataManagementBloc dataBloc;
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(_FakeSettingsEvent());
    registerFallbackValue(_FakeDataManagementEvent());
    registerFallbackValue(_FakeAuthEvent());
  });

  late MockSecureStorageService secureStorage;

  setUp(() async {
    await sl.reset();
    secureStorage = MockSecureStorageService();
    when(
      () => secureStorage.isBiometricEnabled(),
    ).thenAnswer((_) async => false);
    when(() => secureStorage.getPin()).thenAnswer((_) async => null);
    when(
      () => secureStorage.setBiometricEnabled(any()),
    ).thenAnswer((_) async {});
    sl.registerLazySingleton<SecureStorageService>(() => secureStorage);

    settingsBloc = MockSettingsBloc();
    dataBloc = MockDataManagementBloc();
    authBloc = MockAuthBloc();

    when(() => authBloc.state).thenReturn(AuthInitial());
    when(
      () => settingsBloc.state,
    ).thenReturn(const SettingsState(status: SettingsStatus.loaded));
    when(() => dataBloc.state).thenReturn(const DataManagementState());
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: settle,
      accountListState: const AccountListLoaded(accounts: []),
      widget: const SettingsPage(),
      blocProviders: [
        BlocProvider<SettingsBloc>.value(value: settingsBloc),
        BlocProvider<DataManagementBloc>.value(value: dataBloc),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
    );
  }

  group('SettingsPage lifecycle', () {
    testWidgets('requests settings on first build', (tester) async {
      await pumpPage(tester);
      verify(() => settingsBloc.add(const LoadSettings())).called(1);
    });

    testWidgets('shows only a loading indicator in the initial state', (
      tester,
    ) async {
      when(
        () => settingsBloc.state,
      ).thenReturn(const SettingsState(status: SettingsStatus.initial));

      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.byType(AppearanceSettingsSection), findsNothing);
    });

    testWidgets('renders the above-the-fold settings sections once loaded', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byType(AppearanceSettingsSection), findsOneWidget);
      expect(find.byType(GeneralSettingsSection), findsOneWidget);
      expect(find.byType(SecuritySettingsSection), findsOneWidget);
      expect(find.byType(DataManagementSettingsSection), findsOneWidget);
    });

    testWidgets('renders the remaining sections once scrolled into view', (
      tester,
    ) async {
      await pumpPage(tester);

      // The page body is a lazy ListView, so the tail sections only build
      // after they enter the viewport.
      for (final finder in [
        find.byType(HelpSettingsSection),
        find.byType(LegalSettingsSection),
        find.byType(AboutSettingsSection),
      ]) {
        await tester.scrollUntilVisible(
          finder,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(finder, findsOneWidget);
      }
    });
  });

  group('SettingsPage loading overlay', () {
    testWidgets('data-management work shows the "Processing data..." overlay', (
      tester,
    ) async {
      when(() => dataBloc.state).thenReturn(
        const DataManagementState(status: DataManagementStatus.loading),
      );

      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.text('Processing data...'), findsOneWidget);
      expect(find.text('Loading settings...'), findsNothing);
    });

    testWidgets('settings work shows the "Loading settings..." overlay', (
      tester,
    ) async {
      when(
        () => settingsBloc.state,
      ).thenReturn(const SettingsState(status: SettingsStatus.loading));

      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.text('Loading settings...'), findsOneWidget);
      expect(find.text('Processing data...'), findsNothing);
    });

    testWidgets('a package-info load also raises the overlay', (tester) async {
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(
          status: SettingsStatus.loaded,
          packageInfoStatus: PackageInfoStatus.loading,
        ),
      );

      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.text('Loading settings...'), findsOneWidget);
    });

    testWidgets('no overlay is shown when nothing is in flight', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Processing data...'), findsNothing);
      expect(find.text('Loading settings...'), findsNothing);
    });
  });

  group('SettingsPage error surfacing', () {
    // Regression: the settings error toast used to render the literal
    // "Settings Error: " with the reason dropped, because a UI migration
    // stripped the string interpolation.
    testWidgets('a settings error toast includes the failure reason', (
      tester,
    ) async {
      whenListen(
        settingsBloc,
        Stream<SettingsState>.fromIterable([
          const SettingsState(
            status: SettingsStatus.error,
            errorMessage: 'Disk full',
          ),
        ]),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );

      await pumpPage(tester);

      expect(find.text('Settings Error: Disk full'), findsOneWidget);
      verify(() => settingsBloc.add(const ClearSettingsMessage())).called(1);
    });

    // Regression: same dropped interpolation on the package-info path.
    testWidgets('a package-info error toast includes the failure reason', (
      tester,
    ) async {
      whenListen(
        settingsBloc,
        Stream<SettingsState>.fromIterable([
          const SettingsState(
            status: SettingsStatus.loaded,
            packageInfoStatus: PackageInfoStatus.error,
            packageInfoError: 'Manifest unreadable',
          ),
        ]),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );

      await pumpPage(tester);

      expect(
        find.text('Version Info Error: Manifest unreadable'),
        findsOneWidget,
      );
    });

    testWidgets('an error state without a message raises no toast', (
      tester,
    ) async {
      whenListen(
        settingsBloc,
        Stream<SettingsState>.fromIterable([
          const SettingsState(status: SettingsStatus.error),
        ]),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );

      await pumpPage(tester);

      expect(find.textContaining('Settings Error:'), findsNothing);
      verifyNever(() => settingsBloc.add(const ClearSettingsMessage()));
    });

    testWidgets('a data-management success message is surfaced and cleared', (
      tester,
    ) async {
      whenListen(
        dataBloc,
        Stream<DataManagementState>.fromIterable([
          const DataManagementState(
            status: DataManagementStatus.success,
            message: 'Backup complete',
          ),
        ]),
        initialState: const DataManagementState(),
      );

      await pumpPage(tester);

      expect(find.text('Backup complete'), findsOneWidget);
      verify(() => dataBloc.add(const ClearDataManagementMessage())).called(1);
    });

    testWidgets('a data-management error message is surfaced', (tester) async {
      whenListen(
        dataBloc,
        Stream<DataManagementState>.fromIterable([
          const DataManagementState(
            status: DataManagementStatus.error,
            message: 'Restore failed: bad password',
          ),
        ]),
        initialState: const DataManagementState(),
      );

      await pumpPage(tester);

      expect(find.text('Restore failed: bad password'), findsOneWidget);
    });
  });

  group('SettingsPage external links', () {
    // Regression: the failure toast used to read a bare "Could not launch "
    // with the URL dropped by the same lost interpolation as the error toasts.
    testWidgets('a refused launch names the URL it could not open', (
      tester,
    ) async {
      final previous = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _RefusingUrlLauncher();
      addTearDown(() => UrlLauncherPlatform.instance = previous);

      await pumpPage(tester);

      final helpCentre = find.text('Help Center');
      await tester.scrollUntilVisible(
        helpCentre,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(helpCentre);
      await tester.pumpAndSettle();

      expect(
        find.text('Could not launch ${ExternalUrls.help}'),
        findsOneWidget,
      );
    });
  });

  group('SettingsPage actions', () {
    testWidgets('logout dispatches AuthLogoutRequested', (tester) async {
      await pumpPage(tester);

      final logoutButton = find.widgetWithText(AppButton, 'Logout');
      await tester.scrollUntilVisible(
        logoutButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(logoutButton);
      await tester.pump();

      verify(() => authBloc.add(AuthLogoutRequested())).called(1);
    });
  });
}
