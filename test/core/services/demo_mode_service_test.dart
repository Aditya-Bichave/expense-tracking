import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoModeService service;

  setUp(() {
    service = DemoModeService();
    // Reset state properly
    service.exitDemoMode();
    service.enterDemoMode();
  });

  test('getDemoContributionsForGoal should filter by date', () async {
    // Clear default data for this test
    final all = await service.getAllDemoContributions();
    final ids = all.map((c) => c.id).toList();
    await service.deleteDemoContributions(ids);

    // Create specific data for testing
    final tGoalId = 'test_goal';
    final tDate = DateTime(2023, 6, 1);

    final c1 = GoalContributionModel(id: 'd1', goalId: tGoalId, amount: 10, date: tDate, createdAt: tDate);
    final c2 = GoalContributionModel(id: 'd2', goalId: tGoalId, amount: 10, date: tDate.add(Duration(days: 10)), createdAt: tDate); // June 11

    await service.saveDemoContribution(c1);
    await service.saveDemoContribution(c2);

    // Test No Filter
    final filteredAll = await service.getDemoContributionsForGoal(tGoalId);
    expect(filteredAll.length, 2);

    // Test Start Date
    final startFilter = await service.getDemoContributionsForGoal(tGoalId, startDate: DateTime(2023, 6, 5));
    expect(startFilter.length, 1);
    expect(startFilter.first.id, 'd2');

    // Test End Date
    final endFilter = await service.getDemoContributionsForGoal(tGoalId, endDate: DateTime(2023, 6, 5));
    expect(endFilter.length, 1);
    expect(endFilter.first.id, 'd1');
  });
}
