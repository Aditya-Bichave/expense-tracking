import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<IncomeModel> {}

class FakeIncomeModel extends Fake implements IncomeModel {}

void main() {
  late HiveIncomeLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeIncomeModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveIncomeLocalDataSource(mockBox);
  });

  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Test Income',
    amount: 1000.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    categoryId: 'cat1',
  );

  group('addIncome', () {
    test('should add income to Hive box', () async {
      // Arrange
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.addIncome(tIncomeModel);

      // Assert
      verify(() => mockBox.put(tIncomeModel.id, tIncomeModel)).called(1);
    });

    test('should throw CacheFailure when adding fails', () async {
      // Arrange
      when(() => mockBox.put(any(), any())).thenThrow(Exception('Hive Error'));

      // Act & Assert
      expect(
        () => dataSource.addIncome(tIncomeModel),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('deleteIncome', () {
    test('should delete income from Hive box', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.deleteIncome('1');

      // Assert
      verify(() => mockBox.delete('1')).called(1);
    });

    test('should throw CacheFailure when deletion fails', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenThrow(Exception('Hive Error'));

      // Act & Assert
      expect(() => dataSource.deleteIncome('1'), throwsA(isA<CacheFailure>()));
    });
  });

  group('getIncomeById', () {
    test('should return income when found', () async {
      // Arrange
      when(() => mockBox.get(any())).thenReturn(tIncomeModel);

      // Act
      final result = await dataSource.getIncomeById('1');

      // Assert
      expect(result, tIncomeModel);
      verify(() => mockBox.get('1')).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(() => mockBox.get(any())).thenReturn(null);

      // Act
      final result = await dataSource.getIncomeById('1');

      // Assert
      expect(result, null);
    });

    test('should throw CacheFailure when retrieval fails', () async {
      // Arrange
      when(() => mockBox.get(any())).thenThrow(Exception('Hive Error'));

      // Act & Assert
      expect(() => dataSource.getIncomeById('1'), throwsA(isA<CacheFailure>()));
    });
  });

  group('updateIncome', () {
    test('should update income if it exists', () async {
      // Arrange
      when(() => mockBox.containsKey(any())).thenReturn(true);
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.updateIncome(tIncomeModel);

      // Assert
      verify(() => mockBox.put(tIncomeModel.id, tIncomeModel)).called(1);
    });

    test('should throw CacheFailure if income does not exist', () async {
      // Arrange
      when(() => mockBox.containsKey(any())).thenReturn(false);

      // Act & Assert
      expect(
        () => dataSource.updateIncome(tIncomeModel),
        throwsA(isA<CacheFailure>()),
      );
      verify(() => mockBox.containsKey(tIncomeModel.id)).called(1);
      verifyNever(() => mockBox.put(any(), any()));
    });
  });

  group('clearAll', () {
    test('should clear Hive box', () async {
      // Arrange
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      // Act
      await dataSource.clearAll();

      // Assert
      verify(() => mockBox.clear()).called(1);
    });
  });
}
