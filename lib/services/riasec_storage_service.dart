// lib/services/riasec_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/riasec_model.dart';

class RiasecStorageService {
  static final RiasecStorageService instance = RiasecStorageService._init();
  RiasecStorageService._init();

  static const String _progressKey = 'riasec_test_progress';
  static const String _resultKey = 'riasec_test_result';

  // Helper to generate user-specific keys
  String _getUserKey(String key, String userId) => '${key}_$userId';

  /// Save test progress (auto-save)
  Future<void> saveProgress(String userId, RiasecTestProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_getUserKey(_progressKey, userId), jsonString);
      debugPrint('✅ RIASEC test progress saved (${progress.answers.length} answers) for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving RIASEC progress: $e');
      rethrow;
    }
  }

  /// Load saved test progress
  Future<RiasecTestProgress?> loadProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getUserKey(_progressKey, userId));

      if (jsonString == null) {
        debugPrint('ℹ️ No saved RIASEC test progress found for user: $userId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final progress = RiasecTestProgress.fromJson(json);

      debugPrint('✅ RIASEC test progress loaded (${progress.answers.length} answers)');
      return progress;
    } catch (e) {
      debugPrint('❌ Error loading RIASEC progress: $e');
      return null;
    }
  }

  /// Check if there's saved progress
  Future<bool> hasProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_getUserKey(_progressKey, userId));
    } catch (e) {
      debugPrint('❌ Error checking RIASEC progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_progressKey, userId));
      debugPrint('🗑️ RIASEC test progress cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing RIASEC progress: $e');
      rethrow;
    }
  }

  /// Save test result
  Future<void> saveResult(String userId, RiasecResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(result.toJson());
      await prefs.setString(_getUserKey(_resultKey, userId), jsonString);
      debugPrint('✅ RIASEC test result saved for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving RIASEC result: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<RiasecResult?> loadResult(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getUserKey(_resultKey, userId));

      if (jsonString == null) {
        debugPrint('ℹ️ No saved RIASEC test result found for user: $userId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = RiasecResult.fromJson(json);

      debugPrint('✅ RIASEC test result loaded');
      return result;
    } catch (e) {
      debugPrint('❌ Error loading RIASEC result: $e');
      return null;
    }
  }

  /// Clear test result
  Future<void> clearResult(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_resultKey, userId));
      debugPrint('🗑️ RIASEC test result cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing RIASEC result: $e');
      rethrow;
    }
  }

  /// Clear all RIASEC test data
  Future<void> clearAll(String userId) async {
    try {
      await clearProgress(userId);
      await clearResult(userId);
      debugPrint('🗑️ All RIASEC test data cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing all RIASEC data: $e');
      rethrow;
    }
  }
}