import 'package:expense_tracker/features/categories/data/datasources/user_history_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<UserHistoryRuleModel> {}

void main() {
  late MockBox box;
  late HiveUserHistoryLocalDataSource dataSource;

  setUp(() {
    box = MockBox();
    dataSource = HiveUserHistoryLocalDataSource(box);
  });

  final rule = UserHistoryRuleModel(
    ruleId: '1',
    ruleType: 'merchant',
    matcher: 'AMAZON',
    assignedCategoryId: 'cat1',
    timestamp: DateTime(2020, 1, 1),
  );

  test('findRule performs direct lookup with composite key', () async {
    when(() => box.get('merchant_AMAZON')).thenReturn(rule);
    final result = await dataSource.findRule('merchant', 'AMAZON');
    expect(result, rule);
    verify(() => box.get('merchant_AMAZON')).called(1);
  });

  test('saveRule stores using composite key', () async {
    when(() => box.put('merchant_AMAZON', rule)).thenAnswer((_) async {});
    await dataSource.saveRule(rule);
    verify(() => box.put('merchant_AMAZON', rule)).called(1);
  });

  test('deleteRule locates rule by id and deletes', () async {
    when(() => box.keys).thenReturn(['merchant_AMAZON']);
    when(() => box.get('merchant_AMAZON')).thenReturn(rule);
    when(() => box.delete('merchant_AMAZON')).thenAnswer((_) async {});
    await dataSource.deleteRule('1');
    verify(() => box.delete('merchant_AMAZON')).called(1);
  });
}
