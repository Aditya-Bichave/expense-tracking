import 'dart:convert';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetExpenseCategoryDataSource', () {
    late AssetExpenseCategoryDataSource dataSource;

    setUp(() {
      dataSource = AssetExpenseCategoryDataSource();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('getPredefinedCategories loads categories from asset', () async {
      // Corrected json keys to match CategoryModel
      const jsonContent =
          '[{"id": "1", "name": "Food", "iconName": "food", "colorHex": "#FFFFFF", "typeIndex": 0, "isCustom": false}]';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonContent)).buffer,
            );
          });

      final result = await dataSource.getPredefinedCategories();

      expect(result.length, 1);
      expect(result.first.name, 'Food');
      expect(result.first.typeIndex, 0);
    });
  });

  group('AssetIncomeCategoryDataSource', () {
    late AssetIncomeCategoryDataSource dataSource;

    setUp(() {
      dataSource = AssetIncomeCategoryDataSource();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('getPredefinedCategories loads categories from asset', () async {
      // Corrected json keys to match CategoryModel
      const jsonContent =
          '[{"id": "2", "name": "Salary", "iconName": "money", "colorHex": "#000000", "typeIndex": 1, "isCustom": false}]';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonContent)).buffer,
            );
          });

      final result = await dataSource.getPredefinedCategories();

      expect(result.length, 1);
      expect(result.first.name, 'Salary');
      expect(result.first.typeIndex, 1);
    });
  });
}
