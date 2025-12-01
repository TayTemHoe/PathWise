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

  /// Save test progress (auto-save)
  Future<void> saveProgress(BigFiveTestProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_progressKey, jsonString);
      debugPrint('✅ Big Five test progress saved (${progress.answers.length} answers)');
    } catch (e) {
      debugPrint('❌ Error saving Big Five progress: $e');
      rethrow;
    }
  }

  /// Load saved test progress
  Future<BigFiveTestProgress?> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_progressKey);

      if (jsonString == null) {
        debugPrint('ℹ️ No saved Big Five test progress found');
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
  Future<bool> hasProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_progressKey);
    } catch (e) {
      debugPrint('❌ Error checking Big Five progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      debugPrint('🗑️ Big Five test progress cleared');
    } catch (e) {
      debugPrint('❌ Error clearing Big Five progress: $e');
      rethrow;
    }
  }

  /// Save test result
  Future<void> saveResult(BigFiveResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(result.toJson());
      await prefs.setString(_resultKey, jsonString);
      debugPrint('✅ Big Five test result saved');
    } catch (e) {
      debugPrint('❌ Error saving Big Five result: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<BigFiveResult?> loadResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resultKey);

      if (jsonString == null) {
        debugPrint('ℹ️ No saved Big Five test result found');
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
  Future<void> clearResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resultKey);
      debugPrint('🗑️ Big Five test result cleared');
    } catch (e) {
      debugPrint('❌ Error clearing Big Five result: $e');
      rethrow;
    }
  }

  /// Clear all Big Five test data
  Future<void> clearAll() async {
    try {
      await clearProgress();
      await clearResult();
      debugPrint('🗑️ All Big Five test data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all Big Five data: $e');
      rethrow;
    }
  }
}