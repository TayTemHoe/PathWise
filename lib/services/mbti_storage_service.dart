// lib/services/mbti_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/mbti.dart';

class MBTIStorageService {
  static final MBTIStorageService instance = MBTIStorageService._init();
  MBTIStorageService._init();

  static const String _progressKey = 'mbti_test_progress';
  static const String _resultKey = 'mbti_test_result';
  static const String _genderKey = 'mbti_test_gender';

  // Helper to generate user-specific keys
  String _getUserKey(String key, String userId) => '${key}_$userId';

  /// Save test progress (auto-save)
  Future<void> saveProgress(String userId, MBTITestProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_getUserKey(_progressKey, userId), jsonString);
      debugPrint('✅ MBTI test progress saved (${progress.answers.length} answers) for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving MBTI progress: $e');
      rethrow;
    }
  }

  /// Load saved test progress
  Future<MBTITestProgress?> loadProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getUserKey(_progressKey, userId));

      if (jsonString == null) {
        debugPrint('ℹ️ No saved MBTI test progress found for user: $userId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final progress = MBTITestProgress.fromJson(json);

      debugPrint('✅ MBTI test progress loaded (${progress.answers.length} answers)');
      return progress;
    } catch (e) {
      debugPrint('❌ Error loading MBTI progress: $e');
      return null;
    }
  }

  /// Check if there's saved progress
  Future<bool> hasProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_getUserKey(_progressKey, userId));
    } catch (e) {
      debugPrint('❌ Error checking MBTI progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_progressKey, userId));
      debugPrint('🗑️ MBTI test progress cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing MBTI progress: $e');
      rethrow;
    }
  }

  /// Save test result
  Future<void> saveResult(String userId, MBTIResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(result.toJson());
      await prefs.setString(_getUserKey(_resultKey, userId), jsonString);
      debugPrint('✅ MBTI test result saved: ${result.fullCode} for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving MBTI result: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<MBTIResult?> loadResult(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_getUserKey(_resultKey, userId));

      if (jsonString == null) {
        debugPrint('ℹ️ No saved MBTI test result found for user: $userId');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = MBTIResult.fromJson(json);

      debugPrint('✅ MBTI test result loaded: ${result.fullCode}');
      return result;
    } catch (e) {
      debugPrint('❌ Error loading MBTI result: $e');
      return null;
    }
  }

  /// Clear test result
  Future<void> clearResult(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_resultKey, userId));
      debugPrint('🗑️ MBTI test result cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing MBTI result: $e');
      rethrow;
    }
  }

  /// Save selected gender
  Future<void> saveGender(String userId, String gender) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getUserKey(_genderKey, userId), gender);
      debugPrint('✅ Gender saved: $gender for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving gender: $e');
      rethrow;
    }
  }

  /// Load saved gender
  Future<String?> loadGender(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_getUserKey(_genderKey, userId));
    } catch (e) {
      debugPrint('❌ Error loading gender: $e');
      return null;
    }
  }

  /// Clear all MBTI test data
  Future<void> clearAll(String userId) async {
    try {
      await clearProgress(userId);
      await clearResult(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_genderKey, userId));
      debugPrint('🗑️ All MBTI test data cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing all MBTI data: $e');
      rethrow;
    }
  }
}