// lib/repository/mbti_repository.dart

import 'package:flutter/foundation.dart';
import '../model/mbti.dart';
import '../services/mbti_api_service.dart';
import '../services/mbti_storage_service.dart';

class MBTIRepository {
  static final MBTIRepository instance = MBTIRepository._init();
  MBTIRepository._init();

  final MBTIApiService _apiService = MBTIApiService.instance;
  final MBTIStorageService _storageService = MBTIStorageService.instance;

  /// Fetch all test questions (Shared data)
  Future<List<MBTIQuestion>> getQuestions() async {
    try {
      return await _apiService.getQuestions();
    } catch (e) {
      debugPrint('❌ Repository error fetching questions: $e');
      rethrow;
    }
  }

  /// Submit test answers and save result
  Future<MBTIResult> submitTest({
    required String userId, // ADDED
    required List<MBTIAnswer> answers,
    required String gender,
  }) async {
    try {
      debugPrint('📤 Submitting MBTI test (${answers.length} answers) for user: $userId...');

      // Submit to API
      final result = await _apiService.submitAnswers(
        answers: answers,
        gender: gender,
      );

      // Save result locally with userId
      await _storageService.saveResult(userId, result);

      // Clear progress after successful submission
      await _storageService.clearProgress(userId);

      debugPrint('✅ MBTI test submitted and saved: ${result.fullCode}');
      return result;
    } catch (e) {
      debugPrint('❌ Repository error submitting test: $e');
      rethrow;
    }
  }

  /// Save test progress (auto-save)
  Future<void> saveProgress(String userId, MBTITestProgress progress) async {
    try {
      await _storageService.saveProgress(userId, progress);
    } catch (e) {
      debugPrint('❌ Repository error saving progress: $e');
      // Don't rethrow - auto-save failure shouldn't break the app
    }
  }

  /// Load saved test progress
  Future<MBTITestProgress?> loadProgress(String userId) async {
    try {
      return await _storageService.loadProgress(userId);
    } catch (e) {
      debugPrint('❌ Repository error loading progress: $e');
      return null;
    }
  }

  /// Check if there's saved progress
  Future<bool> hasProgress(String userId) async {
    try {
      return await _storageService.hasProgress(userId);
    } catch (e) {
      debugPrint('❌ Repository error checking progress: $e');
      return false;
    }
  }

  /// Clear test progress
  Future<void> clearProgress(String userId) async {
    try {
      await _storageService.clearProgress(userId);
    } catch (e) {
      debugPrint('❌ Repository error clearing progress: $e');
      rethrow;
    }
  }

  /// Load saved test result
  Future<MBTIResult?> loadResult(String userId) async {
    try {
      return await _storageService.loadResult(userId);
    } catch (e) {
      debugPrint('❌ Repository error loading result: $e');
      return null;
    }
  }

  /// Clear test result
  Future<void> clearResult(String userId) async {
    try {
      await _storageService.clearResult(userId);
    } catch (e) {
      debugPrint('❌ Repository error clearing result: $e');
      rethrow;
    }
  }

  /// Save selected gender
  Future<void> saveGender(String userId, String gender) async {
    try {
      await _storageService.saveGender(userId, gender);
    } catch (e) {
      debugPrint('❌ Repository error saving gender: $e');
      // Don't rethrow - gender save failure shouldn't break the app
    }
  }

  /// Load saved gender
  Future<String?> loadGender(String userId) async {
    try {
      return await _storageService.loadGender(userId);
    } catch (e) {
      debugPrint('❌ Repository error loading gender: $e');
      return null;
    }
  }

  /// Restart test (clear all data)
  Future<void> restartTest(String userId) async {
    try {
      debugPrint('🔄 Restarting MBTI test for user: $userId...');
      await _storageService.clearAll(userId);
      debugPrint('✅ MBTI test restarted');
    } catch (e) {
      debugPrint('❌ Repository error restarting test: $e');
      rethrow;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      return await _apiService.testConnection();
    } catch (e) {
      debugPrint('❌ Repository error testing connection: $e');
      return false;
    }
  }

  /// Clear API cache
  void clearCache() {
    _apiService.clearCache();
  }
}