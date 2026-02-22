import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState; // Hide conflicting AuthState

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockUser extends Mock implements User {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockAuthBloc = MockAuthBloc();
  });

  testWidgets('DashboardPage renders loading', (tester) async {
    when(() => mockDashboardBloc.state).thenReturn(const DashboardLoading());
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(MockUser()));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
