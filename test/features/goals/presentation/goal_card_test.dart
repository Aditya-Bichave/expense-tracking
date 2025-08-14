import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/settings/domain/usecases/toggle_app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  testWidgets('pacing info uses onSurface color with opacity', (tester) async {
    final repo = MockSettingsRepository();
    final settingsBloc = SettingsBloc(
      settingsRepository: repo,
      demoModeService: DemoModeService(),
      toggleAppLockUseCase: ToggleAppLockUseCase(repo, MockLocalAuth()),
    );

    final goal = Goal(
      id: 'g1',
      name: 'Trip',
      targetAmount: 1000,
      targetDate: DateTime.now().add(const Duration(days: 60)),
      iconName: 'question',
      description: null,
      status: GoalStatus.active,
      totalSaved: 100,
      createdAt: DateTime.now(),
      achievedAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: GoalCard(goal: goal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pacingFinder = find.textContaining('≈');
    expect(pacingFinder, findsOneWidget);
    final textWidget = tester.widget<Text>(pacingFinder);
    final context = tester.element(pacingFinder);
    final theme = Theme.of(context);
    expect(
      textWidget.style?.color,
      theme.colorScheme.onSurface.withOpacity(0.7),
    );
  });
}
