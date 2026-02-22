import 'package:expense_tracker/features/categories/data/datasources/user_history_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<UserHistoryRuleModel> {}

class FakeUserHistoryRuleModel extends Fake implements UserHistoryRuleModel {
  @override
  String get ruleType => RuleType.merchant.name;
  @override
  String get matcher => 'matcher';
  @override
  String get ruleId => '1';
  @override
  String get assignedCategoryId => 'cat1';
}

void main() {
  late HiveUserHistoryLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeUserHistoryRuleModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveUserHistoryLocalDataSource(mockBox);
  });

  test('findRule returns rule if found', () async {
    final tRule = FakeUserHistoryRuleModel();
    when(() => mockBox.values).thenReturn([tRule]);

    final result = await dataSource.findRule(RuleType.merchant.name, 'matcher');

    expect(result, tRule);
  });

  test('saveRule calls box.put', () async {
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {
      return;
    });

    await dataSource.saveRule(FakeUserHistoryRuleModel());

    verify(() => mockBox.put('1', any())).called(1);
  });
}
