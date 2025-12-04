// lib/services/big_five_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/big_five_model.dart';

class BigFiveStorageService {
  static final BigFiveStorageService instance = BigFiveStorageService._init();
  BigFiveStorageService._init();

  static const String _progressKey = 'big_five_test_progress';
  static const String _resultKey = 'big_five_test_result';

  // Helper to generate user-specific keys
  String _getUserKey(String key, String userId) => '${key}_$userId';

  /// Save test progress (auto-save)
  Future<void> saveProgress(String userId, BigFiveTestProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_getUserKey(_progressKey, userId), jsonString);
      debugPrint('✅ Big Five test progress saved (${progress.answers.length} answers) for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving Big Five progress: $e');
      rethrow;
    }
  }

  /// Load saved test progress
  Future<BigFiveTestProgress?> loadProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getUserKey(_progressKey, userId));

      if (jsonString == null) {
        debugPrint('ℹ️ No saved Big Five test progress found for user: $userId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final progress = BigFiveTestProgress.fromJson(json);

      debugPrint('✅ Big Five test progress loaded (${progress.answers.length} answers)');
      return progress;
    } catch (e) {
      debugPrint('❌ Error loading Big Five progress: $e');
      return null;
    }
  }

  /// Check if there's saved progress
  Future<bool> hasProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_getUserKey(_progressKey, userId));
    } catch (e) {
      debugPrint('❌ Error checking Big Five progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_progressKey, userId));
      debugPrint('🗑️ Big Five test progress cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing Big Five progress: $e');
      rethrow;
    }
  }

  /// Save test result
  Future<void> saveResult(String userId, BigFiveResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(result.toJson());
      await prefs.setString(_getUserKey(_resultKey, userId), jsonString);
      debugPrint('✅ Big Five test result saved for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving Big Five result: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<BigFiveResult?> loadResult(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getUserKey(_resultKey, userId));

      if (jsonString == null) {
        debugPrint('ℹ️ No saved Big Five test result found for user: $userId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = BigFiveResult.fromJson(json);

      debugPrint('✅ Big Five test result loaded');
      return result;
    } catch (e) {
      debugPrint('❌ Error loading Big Five result: $e');
      return null;
    }
  }

  /// Clear test result
  Future<void> clearResult(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_resultKey, userId));
      debugPrint('🗑️ Big Five test result cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing Big Five result: $e');
      rethrow;
    }
  }

  /// Clear all Big Five test data
  Future<void> clearAll(String userId) async {
    try {
      await clearProgress(userId);
      await clearResult(userId);
      debugPrint('🗑️ All Big Five test data cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing all Big Five data: $e');
      rethrow;
    }
  }
}