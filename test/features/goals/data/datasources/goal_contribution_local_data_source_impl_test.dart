import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:simple_logger/simple_logger.dart';

class MockBox extends Mock implements Box<GoalContributionModel> {}

class FakeGoalContributionModel extends Fake implements GoalContributionModel {}

void main() {
  late HiveContributionLocalDataSource dataSource;
  late MockBox mockBox;

  final tContribution = GoalContributionModel(
    id: '1',
    goalId: 'g1',
    amount: 100,
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeGoalContributionModel());
    log.setLevel(
      Level.OFF,
      includeCallerInfo: false,
    ); // Silence expected errors
  });

  tearDownAll(() {
    log.setLevel(Level.INFO);
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveContributionLocalDataSource(mockBox);
  });

  group('HiveContributionLocalDataSource', () {
    group('saveContribution', () {
      test('should save contribution to box', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

        await dataSource.saveContribution(tContribution);

        verify(() => mockBox.put(tContribution.id, tContribution)).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(
          () => mockBox.put(any(), any()),
        ).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.saveContribution(tContribution),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getAllContributions', () {
      test('should return list of contributions from box', () async {
        final List<GoalContributionModel> tList = [tContribution];
        when(() => mockBox.values).thenReturn(tList);

        final result = await dataSource.getAllContributions();

        expect(result, equals(tList));
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.values).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.getAllContributions(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getContributionById', () {
      test('should return contribution if found', () async {
        when(() => mockBox.get(any())).thenReturn(tContribution);

        final result = await dataSource.getContributionById(tContribution.id);

        expect(result, equals(tContribution));
        verify(() => mockBox.get(tContribution.id)).called(1);
      });

      test('should return null if not found', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        final result = await dataSource.getContributionById('non-existent');

        expect(result, isNull);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.get(any())).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.getContributionById(tContribution.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getContributionsForGoal', () {
      test('should return filtered list', () async {
        final tContribution2 = GoalContributionModel(
          id: '2',
          goalId: 'g2', // Different goal
          amount: 50,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );
        final List<GoalContributionModel> tList = [
          tContribution,
          tContribution2,
        ];
        when(() => mockBox.values).thenReturn(tList);

        final result = await dataSource.getContributionsForGoal('g1');

        expect(result.length, 1);
        expect(result.first.id, '1');
      });
    });

    group('deleteContribution', () {
      test('should delete contribution from box', () async {
        when(() => mockBox.delete(any())).thenAnswer((_) async => {});

        await dataSource.deleteContribution(tContribution.id);

        verify(() => mockBox.delete(tContribution.id)).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.delete(any())).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.deleteContribution(tContribution.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('clearAllContributions', () {
      test('should clear box', () async {
        when(() => mockBox.clear()).thenAnswer((_) async => 0);

        await dataSource.clearAllContributions();

        verify(() => mockBox.clear()).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.clear()).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.clearAllContributions(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });
  });
}
