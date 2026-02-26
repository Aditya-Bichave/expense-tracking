import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class MockLogContributionBloc
    extends MockBloc<LogContributionEvent, LogContributionState>
    implements LogContributionBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockLogContributionBloc mockLogBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockLogBloc = MockLogContributionBloc();
    mockSettingsBloc = MockSettingsBloc();
  });

  testWidgets('LogContributionSheet renders', (tester) async {
    when(() => mockLogBloc.state).thenReturn(LogContributionState.initial('1'));
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<LogContributionBloc>.value(value: mockLogBloc),
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          ],
          child: Scaffold(body: const LogContributionSheet()),
        ),
      ),
    );

    // Check for title or key element
    expect(find.text('Log Contribution'), findsOneWidget);
  });
}
