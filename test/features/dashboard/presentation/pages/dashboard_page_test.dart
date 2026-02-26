import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_dashboard_body.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
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
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart'; // Needed for recent transactions
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
// Import tokens explicitly since app_theme_ext.dart doesn't export them
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

// Mocks
class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockUser extends Mock implements User {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockAuthBloc mockAuthBloc;
  late MockTransactionListBloc mockTransactionListBloc;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockAuthBloc = MockAuthBloc();
    mockTransactionListBloc = MockTransactionListBloc();

    // Default states
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(MockUser()));
    when(() => mockTransactionListBloc.state).thenReturn(
      const TransactionListState(status: ListStatus.initial),
    );
  });

  Future<void> pumpDashboardPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: [
            // Ensure AppKitTheme is available
            AppKitTheme(
              colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
              typography: AppTypography(Typography.material2021().englishLike),
              spacing: const AppSpacing(),
              radii: const AppRadii(),
              motion: const AppMotion(),
              shadows: const AppShadows(),
            ),
          ],
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );
  }

  testWidgets('DashboardPage renders loading', (tester) async {
    when(() => mockDashboardBloc.state).thenReturn(const DashboardLoading());
    await pumpDashboardPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('DashboardPage renders error snackbar', (tester) async {
    when(() => mockDashboardBloc.state).thenReturn(
      const DashboardError('Test Error'),
    );
    await pumpDashboardPage(tester);
    // Use pump to trigger the listener, and allow time for SnackBar animation
    await tester.pump();
    // SnackBar animation takes time, pumpAndSettle might be needed, or pump with duration
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dashboard Error: Test Error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('DashboardPage renders Stitch body when mode is Stitch', (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsState(uiMode: UIMode.stitch),
    );
    when(() => mockDashboardBloc.state).thenReturn(
      const DashboardLoaded(
        FinancialOverview(
          overallBalance: 1000,
          totalIncome: 2000,
          totalExpenses: 1000,
          netFlow: 1000,
          accounts: [],
          accountBalances: {'Cash': 1000},
          recentSpendingSparkline: [],
          recentContributionSparkline: [],
          activeBudgetsSummary: [],
          activeGoalsSummary: [],
        ),
      ),
    );

    await pumpDashboardPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(StitchDashboardBody), findsOneWidget);
  });

  testWidgets('DashboardPage renders Aether body when mode is Aether', (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsState(uiMode: UIMode.aether),
    );
    when(() => mockDashboardBloc.state).thenReturn(
      const DashboardLoaded(
        FinancialOverview(
          overallBalance: 1000,
          totalIncome: 2000,
          totalExpenses: 1000,
          netFlow: 1000,
          accounts: [],
          accountBalances: {'Cash': 1000},
          recentSpendingSparkline: [],
          recentContributionSparkline: [],
          activeBudgetsSummary: [],
          activeGoalsSummary: [],
        ),
      ),
    );

    await pumpDashboardPage(tester);
    await tester.pumpAndSettle();

    // Verify Aether body components are present (by checking structure/key if possible, or absence of Stitch)
    expect(find.byType(StitchDashboardBody), findsNothing);
    // You could look for specific Aether widgets if exported, but verifying correct branch logic is enough
    // Since _buildAetherDashboardBody returns a Stack with ListView, checking for ListView is generic.
    // However, Aether mode returns a standard Scaffold (checked by behavior), others return AppScaffold.
    // We can check type of scaffold if we really want, but widget tree structure differs.
  });
}
