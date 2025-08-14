import 'dart:convert';
import 'dart:typed_data';

import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserHistoryRepository extends Mock implements UserHistoryRepository {}

class MockMerchantCategoryRepository extends Mock
    implements MerchantCategoryRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CategorizeTransactionUseCase usecase;
  late MockUserHistoryRepository userHistoryRepository;
  late MockMerchantCategoryRepository merchantRepo;
  late MockCategoryRepository categoryRepo;
  int loadCount = 0;

  setUpAll(() {
    registerFallbackValue(RuleType.merchant);
  });

  setUp(() {
    userHistoryRepository = MockUserHistoryRepository();
    merchantRepo = MockMerchantCategoryRepository();
    categoryRepo = MockCategoryRepository();

    when(
      () => userHistoryRepository.findRule(any(), any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => merchantRepo.getDefaultCategoryId(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => categoryRepo.getCategoryById(any()),
    ).thenAnswer((_) async => const Right(Category.uncategorized));

    final data = utf8.encode('{"uncategorized": ["test"]}');
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final String key = const StringCodec().decodeMessage(message!)!;
        if (key == 'assets/data/category_keywords.json') {
          loadCount++;
          return ByteData.view(Uint8List.fromList(data).buffer);
        }
        return null;
      },
    );

    usecase = CategorizeTransactionUseCase(
      userHistoryRepository: userHistoryRepository,
      merchantCategoryRepository: merchantRepo,
      categoryRepository: categoryRepo,
    );
  });

  test('concurrent calls load keywords once', () async {
    final params = CategorizeTransactionParams(description: 'test');
    await Future.wait([usecase(params), usecase(params)]);
    expect(loadCount, 1);
  });
}
