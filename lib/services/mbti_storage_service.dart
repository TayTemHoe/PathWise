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

  /// Save test progress (auto-save)
  Future<void> saveProgress(MBTITestProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_progressKey, jsonString);
      debugPrint('✅ MBTI test progress saved (${progress.answers.length} answers)');
    } catch (e) {
      debugPrint('❌ Error saving MBTI progress: $e');
      rethrow;
    }
  }

  /// Load saved test progress
  Future<MBTITestProgress?> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_progressKey);

      if (jsonString == null) {
        debugPrint('ℹ️ No saved MBTI test progress found');
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
  Future<bool> hasProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_progressKey);
    } catch (e) {
      debugPrint('❌ Error checking MBTI progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      debugPrint('🗑️ MBTI test progress cleared');
    } catch (e) {
      debugPrint('❌ Error clearing MBTI progress: $e');
      rethrow;
    }
  }

  /// Save test result
  Future<void> saveResult(MBTIResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(result.toJson());
      await prefs.setString(_resultKey, jsonString);
      debugPrint('✅ MBTI test result saved: ${result.fullCode}');
    } catch (e) {
      debugPrint('❌ Error saving MBTI result: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<MBTIResult?> loadResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resultKey);

      if (jsonString == null) {
        debugPrint('ℹ️ No saved MBTI test result found');
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
  Future<void> clearResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resultKey);
      debugPrint('🗑️ MBTI test result cleared');
    } catch (e) {
      debugPrint('❌ Error clearing MBTI result: $e');
      rethrow;
    }
  }

  /// Save selected gender
  Future<void> saveGender(String gender) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_genderKey, gender);
      debugPrint('✅ Gender saved: $gender');
    } catch (e) {
      debugPrint('❌ Error saving gender: $e');
      rethrow;
    }
  }

  /// Load saved gender
  Future<String?> loadGender() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_genderKey);
    } catch (e) {
      debugPrint('❌ Error loading gender: $e');
      return null;
    }
  }

  /// Clear all MBTI test data
  Future<void> clearAll() async {
    try {
      await clearProgress();
      await clearResult();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_genderKey);
      debugPrint('🗑️ All MBTI test data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all MBTI data: $e');
      rethrow;
    }
  }
}