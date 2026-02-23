import 'dart:convert';
import 'package:expense_tracker/features/categories/data/datasources/merchant_category_data_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetMerchantCategoryDataSource', () {
    late AssetMerchantCategoryDataSource dataSource;

    setUp(() {
      dataSource = AssetMerchantCategoryDataSource();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('getDefaultCategoryId loads data and returns category ID', () async {
      const jsonContent = '{"uber": "transport-id", "starbucks": "coffee-id"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonContent)).buffer,
            );
          });

      final result = await dataSource.getDefaultCategoryId('Uber');

      expect(result, 'transport-id');
    });

    test('getDefaultCategoryId is case insensitive', () async {
      const jsonContent = '{"uber": "transport-id", "starbucks": "coffee-id"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonContent)).buffer,
            );
          });

      final result = await dataSource.getDefaultCategoryId('STARBUCKS');

      expect(result, 'coffee-id');
    });

    test('getDefaultCategoryId returns null for unknown merchant', () async {
      const jsonContent = '{"uber": "transport-id"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            return ByteData.view(
              Uint8List.fromList(utf8.encode(jsonContent)).buffer,
            );
          });

      final result = await dataSource.getDefaultCategoryId('Unknown');

      expect(result, null);
    });
  });
}
