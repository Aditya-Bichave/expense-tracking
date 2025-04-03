import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class MerchantCategoryDataSource {
  /// Looks up the default category ID for a given merchant identifier.
  Future<String?> getDefaultCategoryId(String merchantIdentifier);
}

class AssetMerchantCategoryDataSource implements MerchantCategoryDataSource {
  Map<String, String>? _cachedDb; // Cache the loaded JSON map
  final String _assetPath = 'assets/data/merchant_categories.json';
  bool _isLoading = false; // Prevent concurrent loading

  Future<Map<String, String>> _loadDb() async {
    if (_cachedDb != null) return _cachedDb!;
    if (_isLoading) {
      // Avoid race conditions if called multiple times before completion
      await Future.delayed(
          Duration(milliseconds: 100)); // Small delay and retry
      return _loadDb();
    }

    _isLoading = true;
    log.info("Loading merchant category database from asset: $_assetPath");
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      // Expecting a Map<String, String> directly from JSON
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;

      // Convert keys and values to lowercase for case-insensitive matching
      _cachedDb = jsonMap
          .map((key, value) => MapEntry(key.toLowerCase(), value.toString()));

      log.info(
          "Successfully loaded and cached ${_cachedDb!.length} merchant categories.");
      return _cachedDb!;
    } on FormatException catch (e, s) {
      log.severe(
          "Failed to parse merchant categories JSON from asset '$_assetPath'$e$s");
      _cachedDb = {}; // Set empty cache on error to prevent retries
      throw const CacheFailure(
          'Invalid format in merchant categories asset file.');
    } catch (e, s) {
      log.severe(
          "Failed to load merchant categories from asset '$_assetPath'$e$s");
      _cachedDb = {}; // Set empty cache on error
      throw CacheFailure('Could not load merchant categories: ${e.toString()}');
    } finally {
      _isLoading = false;
    }
  }

  @override
  Future<String?> getDefaultCategoryId(String merchantIdentifier) async {
    try {
      final db = await _loadDb();
      final lowerCaseIdentifier = merchantIdentifier.toLowerCase();

      // Simple exact match (case-insensitive due to loading)
      final categoryId = db[lowerCaseIdentifier];

      if (categoryId != null) {
        log.fine(
            "Found default category '$categoryId' for merchant '$merchantIdentifier'.");
      } else {
        log.fine(
            "No default category found for merchant '$merchantIdentifier'.");
        // TODO: Consider more advanced matching later if needed (e.g., partial matches, aliases)
      }
      return categoryId;
    } catch (e) {
      // Errors during loading are handled in _loadDb, but catch potential future issues
      log.severe(
          "Error looking up default category for '$merchantIdentifier': $e");
      return null; // Return null on error
    }
  }
}
