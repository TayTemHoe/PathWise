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

  /// Save test progress (auto-save)
  Future<void> saveProgress(RiasecTestProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_progressKey, jsonString);
      debugPrint('✅ RIASEC test progress saved (${progress.answers.length} answers)');
    } catch (e) {
      debugPrint('❌ Error saving RIASEC progress: $e');
      rethrow;
    }
  }

  /// Load saved test progress
  Future<RiasecTestProgress?> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_progressKey);

      if (jsonString == null) {
        debugPrint('ℹ️ No saved RIASEC test progress found');
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
  Future<bool> hasProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_progressKey);
    } catch (e) {
      debugPrint('❌ Error checking RIASEC progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      debugPrint('🗑️ RIASEC test progress cleared');
    } catch (e) {
      debugPrint('❌ Error clearing RIASEC progress: $e');
      rethrow;
    }
  }

  /// Save test result
  Future<void> saveResult(RiasecResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(result.toJson());
      await prefs.setString(_resultKey, jsonString);
      debugPrint('✅ RIASEC test result saved');
    } catch (e) {
      debugPrint('❌ Error saving RIASEC result: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<RiasecResult?> loadResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resultKey);

      if (jsonString == null) {
        debugPrint('ℹ️ No saved RIASEC test result found');
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
  Future<void> clearResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resultKey);
      debugPrint('🗑️ RIASEC test result cleared');
    } catch (e) {
      debugPrint('❌ Error clearing RIASEC result: $e');
      rethrow;
    }
  }

  /// Clear all RIASEC test data
  Future<void> clearAll() async {
    try {
      await clearProgress();
      await clearResult();
      debugPrint('🗑️ All RIASEC test data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all RIASEC data: $e');
      rethrow;
    }
  }
}